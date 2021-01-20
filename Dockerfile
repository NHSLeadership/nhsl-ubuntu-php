FROM ubuntu:bionic
LABEL maintainer="devops@nhsx.uk"

ARG PHPV
ARG DEBIAN_FRONTEND=noninteractive
ENV PHP_VERSION=$PHPV

# copy in apt repos for openresty, nginx, php
COPY conf/etc/apt/sources.list.d/*.new /etc/apt/sources.list.d/
COPY php-redis_4.2.0-1_amd64.deb /
COPY scripts/start-container.sh /

RUN \
  # Install basic packages
  apt-get update && \
  apt-get upgrade -y && \
  apt-get dist-upgrade -y && \
  apt-get install \
    busybox-static \
    ca-certificates \
    curl \
    gettext \
    git \
    gpg-agent \
    ghostscript \
    gnupg \
    supervisor \
    ssh \
    nano \
    netcat \
    ssmtp \
    unzip \
    zip \
    --no-install-recommends -y && \
  cd /etc/apt/sources.list.d && \
  # we have .new rename to .list so not picked up until they can be validated
  for f in *.new; do mv $f `basename $f .new`.list; done && \
  # add keys for ondrej php/nginx and openresty PPAs
  apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 97992D8CFD2E2D02 && \
  apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 4F4EA0AAE5267A6C && \
  apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 2E61F1063ED1B4FD && \
  # start actually installing our server packages
  apt-get update && \
  apt-get install \
    nginx \
# commented out due to broken package in PPA
#    libnginx-mod-brotli \
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
    php${PHP_VERSION}-intl \
    --no-install-recommends -y && \
    # We have to install an old version of php-redis due to bug. See https://github.com/phpredis/phpredis/issues/1620
    #    when fix then add php${PHP_VERSION}-redis back in above.
    if [ $PHP_VERSION = "7.2" ]; then dpkg -i /php-redis_4.2.0-1_amd64.deb; else apt-get install php-redis --no-install-recommends -y; fi && \
    mkdir -p /var/run/php && \
    cd /tmp && \
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
      apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    ## Add in PHP FPM health checker script
    curl https://raw.githubusercontent.com/renatomefi/php-fpm-healthcheck/master/php-fpm-healthcheck --output /usr/local/bin/php-fpm-healthcheck && \
    chmod +x /usr/local/bin/php-fpm-healthcheck

# supervisord configs
COPY conf/supervisor/supervisord.conf /etc/supervisord.conf
COPY conf/supervisor/enabled/* /etc/supervisor/conf.d/

# Web server config
COPY conf/nginx/ /etc/nginx/

# fix php supervisor version
# Modify PHP-FPM configuration files to set common properties and listen on socket.
# We also remove /etc/ssmtp/ssmtp.conf because we don't need all that config. It gets
# configured at container runtime in 004-mail.sh in s6.
#  rm -rf /etc/php/${PHP_VERSION}/cli/php.ini && \
#  ln -s /etc/php/${PHP_VERSION}/fpm/php.ini /etc/php/${PHP_VERSION}/cli/php.ini && \
RUN \
  envsubst < /etc/supervisor/conf.d/php-fpm.conf.template > /etc/supervisor/conf.d/php-fpm.conf && \
  rm -f /etc/supervisor/conf.d/php-fpm.conf.template && \
  sed -i -e 's|variables_order = "GPCS"|variables_order = "EGPCS"|g' /etc/php/${PHP_VERSION}/fpm/php.ini && \
  sed -i -e 's|variables_order = "GPCS"|variables_order = "EGPCS"|g' /etc/php/${PHP_VERSION}/cli/php.ini && \
  sed -i -e 's|;clear_env = no|clear_env = no|g' /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf && \
  sed -i -e "s|;ping.path = /ping|ping.path = /healthz|g" /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf && \
  sed -i -e "s|;ping.response = pong|ping.response = OK|g" /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf && \
  sed -i "s|;date.timezone =.*|date.timezone = UTC|" /etc/php/${PHP_VERSION}/fpm/php.ini && \
  sed -i "s|upload_max_filesize = .*|upload_max_filesize = 1G|" /etc/php/${PHP_VERSION}/fpm/php.ini && \
  sed -i "s|post_max_size = .*|post_max_size = 512M|" /etc/php/${PHP_VERSION}/fpm/php.ini && \
  sed -i "s|;cgi.fix_pathinfo=1|cgi.fix_pathinfo=0|" /etc/php/${PHP_VERSION}/fpm/php.ini && \
  sed -i -e "s|error_log =.*|error_log = \/proc\/self\/fd\/2|" /etc/php/${PHP_VERSION}/fpm/php-fpm.conf && \
  sed -i -e "s|;daemonize\s*=\s*yes|daemonize = no|g" /etc/php/${PHP_VERSION}/fpm/php-fpm.conf && \
  sed -i "s|;catch_workers_output = .*|catch_workers_output = yes|" /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf && \
  sed -i "s|listen = .*|listen = \/var\/run\/php-fpm.sock|" /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf && \
  sed -i -e "s|pid =.*|pid = \/var\/run\/php-fpm.pid|" /etc/php/${PHP_VERSION}/fpm/php-fpm.conf && \
  sed -i "s|user = www-data|user = nobody|" /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf && \
  sed -i "s|group = www-data|group = nogroup|" /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf && \
  sed -i -e 's|atatus.trace.response_time = 2000|atatus.trace.response_time = 1500|g' /etc/php/${PHP_VERSION}/fpm/conf.d/20-atatus.ini && \
  sed -i -e 's|atatus.agent.log_file = "/var/log/atatus/agent.log"|atatus.agent.log_file = "/dev/stdout"|g' /etc/php/${PHP_VERSION}/fpm/conf.d/20-atatus.ini && \
  sed -i -e 's|atatus.collector.log_file = "/var/log/atatus/collector.log"|atatus.collector.log_file = "/dev/stdout"|g' /etc/php/${PHP_VERSION}/fpm/conf.d/20-atatus.ini && \
  rm -rf /etc/nginx/sites-enabled/default && \
  rm -rf /etc/ssmtp/ssmtp.conf && \
  mkdir -p /src/public && \
  chown -R nobody:nogroup /src && \
  chmod +x /start-container.sh && \
  date > /build_image_date

CMD ["/start-container.sh"]
