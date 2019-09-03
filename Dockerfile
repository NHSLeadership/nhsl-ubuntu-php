FROM ubuntu:bionic
LABEL maintainer="devops@nhsx.uk"

ARG PHPV

ENV S6_OVERLAY_VERSION 1.22.1.0
ENV PHP_VERSION $PHPV
ENV DEBIAN_FRONTEND noninteractive

# Install useful packages and Nginx/PHP
RUN \
  apt-get update && \
  apt-get install \
    cron \
    curl \
    gpg-agent \
    software-properties-common \
    --no-install-recommends -y && \
#  add-apt-repository -y ppa:ondrej/nginx-mainline && \
  add-apt-repository -y ppa:ondrej/php && \
  curl https://openresty.org/package/pubkey.gpg | apt-key add - && \
  add-apt-repository -y "deb http://openresty.org/package/ubuntu $(lsb_release -sc) main" && \
  apt-get update && \
  apt-get install \
    openresty \
    php${PHP_VERSION}-fpm \
    php${PHP_VERSION}-cli \
    php${PHP_VERSION}-mysql \
    php${PHP_VERSION}-mysqli \
    php${PHP_VERSION}-memcached \
    php${PHP_VERSION}-curl \
    php${PHP_VERSION}-dom \
    php${PHP_VERSION}-exif \
    php${PHP_VERSION}-ftp \
    php${PHP_VERSION}-gd \
    php${PHP_VERSION}-iconv \
    php${PHP_VERSION}-mbstring \
    php${PHP_VERSION}-pdo \
    php${PHP_VERSION}-posix \
    php${PHP_VERSION}-soap \
    php${PHP_VERSION}-zip \
    php${PHP_VERSION}-ldap \
    php${PHP_VERSION}-bcmath \
    php${PHP_VERSION}-calendar \
    php${PHP_VERSION}-gettext \
    php${PHP_VERSION}-json \
    php${PHP_VERSION}-apcu \
    php${PHP_VERSION}-phar \
    php${PHP_VERSION}-sockets \
    php${PHP_VERSION}-tidy \
    php${PHP_VERSION}-wddx \
    php${PHP_VERSION}-xmlreader \
    php${PHP_VERSION}-xsl \
    php${PHP_VERSION}-opcache \
    php${PHP_VERSION}-imagick \
    php${PHP_VERSION}-ctype \
    php${PHP_VERSION}-sqlite3 \
    php${PHP_VERSION}-redis \
    php${PHP_VERSION}-intl \
    --no-install-recommends -y && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

## Install s6 overlay
RUN \
  cd /tmp && \
  curl https://keybase.io/justcontainers/key.asc | gpg --import && \
  curl -LO https://github.com/just-containers/s6-overlay/releases/download/v$S6_OVERLAY_VERSION/s6-overlay-amd64.tar.gz && \
  curl -LO https://github.com/just-containers/s6-overlay/releases/download/v$S6_OVERLAY_VERSION/s6-overlay-amd64.tar.gz.sig && \
  gpg --verify s6-overlay-amd64.tar.gz.sig s6-overlay-amd64.tar.gz && \
  tar xzf s6-overlay-amd64.tar.gz -C / && \
  rm s6-overlay-amd64.tar.gz && \
  rm s6-overlay-amd64.tar.gz.sig

## Add global Composer
RUN curl -sS https://getcomposer.org/installer | php \
    && mv composer.phar /usr/local/bin/composer \
    && chmod a+x /usr/local/bin/composer

## Add Atatus GPG key and repo
RUN apt-get install curl --no-install-recommends -y && \
  curl https://s3.amazonaws.com/atatus-artifacts/gpg/atatus.gpg | apt-key add - && \
  echo "deb https://s3.amazonaws.com/atatus-artifacts/atatus-php/debian stable main" \
  | tee -a /etc/apt/sources.list.d/atatus-php-agent.list && \
  apt-get update && \
  apt-get install atatus-php-agent --no-install-recommends -y && \
  apt-get remove curl -y

# s6 overlay configs
COPY conf/s6/services/ /etc/services.d/
COPY conf/s6/cont-init/ /etc/cont-init.d/
RUN \
  find /etc/services.d/ -type f -exec chmod 755 -- {} + && \
  find /etc/cont-init.d/ -type f -exec chmod 755 -- {} +

# Nginx config
COPY conf/openresty/ /etc/openresty/

# symlink so PHP CLI and FPM use the same php.ini
# Modify PHP-FPM configuration files to set common properties and listen on socket
RUN \
  rm -rf /etc/php/${PHP_VERSION}/cli/php.ini && \
  ln -s /etc/php/${PHP_VERSION}/fpm/php.ini /etc/php/${PHP_VERSION}/cli/php.ini && \
  sed -i "s|;date.timezone =.*|date.timezone = UTC|" /etc/php/${PHP_VERSION}/fpm/php.ini && \
  sed -i "s|upload_max_filesize = .*|upload_max_filesize = 100M|" /etc/php/${PHP_VERSION}/fpm/php.ini && \
  sed -i "s|post_max_size = .*|post_max_size = 12M|" /etc/php/${PHP_VERSION}/fpm/php.ini && \
  sed -i "s|;cgi.fix_pathinfo=1|cgi.fix_pathinfo=0|" /etc/php/${PHP_VERSION}/fpm/php.ini && \
  sed -i -e "s|error_log =.*|error_log = \/proc\/self\/fd\/2|" /etc/php/${PHP_VERSION}/fpm/php-fpm.conf && \
  sed -i -e "s|;daemonize\s*=\s*yes|daemonize = no|g" /etc/php/${PHP_VERSION}/fpm/php-fpm.conf && \
  sed -i "s|;catch_workers_output = .*|catch_workers_output = yes|" /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf && \
  sed -i "s|listen = .*|listen = \/var\/run\/php-fpm.sock|" /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf && \
  sed -i -e "s|pid =.*|pid = \/var\/run\/php-fpm.pid|" /etc/php/${PHP_VERSION}/fpm/php-fpm.conf

# Clean stuff up
RUN \
  apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
  mkdir -p /src/public && \
  chown -R www-data:www-data /src

ENTRYPOINT [ "/init" ]
