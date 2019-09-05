FROM ubuntu:bionic
LABEL maintainer="devops@nhsx.uk"

ARG PHPV
ARG DEBIAN_FRONTEND=noninteractive

ENV S6_OVERLAY_VERSION=1.22.1.0
ENV PHP_VERSION=$PHPV
ENV WEBSRV=openresty

# copy in apt repos for openresty, nginx, php
COPY conf/etc/apt/sources.list.d/ /etc/apt/sources.list.d/

RUN \
  # Install basic packages
  apt-get update && \
  apt-get upgrade -y && \
  apt-get dist-upgrade -y && \
  apt-get install \
    ca-certificates \
    cron \
    curl \
    gpg-agent \
    gnupg \
    --no-install-recommends -y && \
  cd /etc/apt/sources.list.d && \
  # we have .new rename to .list so not picked up until they can be validated
  for f in *.new; do mv $f `basename $f .new`.list; done && \
  # add keys for ondrej php/nginx and openresty PPAs
  apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 4F4EA0AAE5267A6C && \
  apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 2E61F1063ED1B4FD && \
  # start actually installing our server packages
  apt-get update && \
  apt-get install \
    ${WEBSRV} \
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
    # Install s6 overlay
    cd /tmp && \
      curl https://keybase.io/justcontainers/key.asc | gpg --import && \
      curl -LO https://github.com/just-containers/s6-overlay/releases/download/v$S6_OVERLAY_VERSION/s6-overlay-amd64.tar.gz && \
      curl -LO https://github.com/just-containers/s6-overlay/releases/download/v$S6_OVERLAY_VERSION/s6-overlay-amd64.tar.gz.sig && \
      gpg --verify s6-overlay-amd64.tar.gz.sig s6-overlay-amd64.tar.gz && \
      tar xzf s6-overlay-amd64.tar.gz -C / && \
      rm s6-overlay-amd64.tar.gz && \
      rm s6-overlay-amd64.tar.gz.sig && \
    ## Add global Composer
      curl -sS https://getcomposer.org/installer | php && \
      mv composer.phar /usr/local/bin/composer && \
      chmod a+x /usr/local/bin/composer && \
    ## Add Atatus GPG key and repo
    curl https://s3.amazonaws.com/atatus-artifacts/gpg/atatus.gpg | apt-key add - && \
      echo "deb https://s3.amazonaws.com/atatus-artifacts/atatus-php/debian stable main" \
      | tee -a /etc/apt/sources.list.d/atatus-php-agent.list && \
      apt-get update && \
      apt-get install atatus-php-agent --no-install-recommends -y && \
      apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# s6 overlay configs
COPY conf/s6/services/ /etc/services.d/
COPY conf/s6/cont-init/ /etc/cont-init.d/
RUN \
  find /etc/services.d/ -type f -exec chmod 755 -- {} + && \
  find /etc/cont-init.d/ -type f -exec chmod 755 -- {} +

# Web server config
COPY conf/$WEBSRV/ /etc/$WEBSRV/

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
  sed -i -e "s|pid =.*|pid = \/var\/run\/php-fpm.pid|" /etc/php/${PHP_VERSION}/fpm/php-fpm.conf && \
  mkdir -p /src/public && \
  chown -R www-data:www-data /src

ENTRYPOINT [ "/init" ]
