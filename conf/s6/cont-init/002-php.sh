#!/usr/bin/with-contenv sh
set -e

### Set healthz checker
sed -i -e "s|;ping.path = /ping|ping.path = /healthz|g" /etc/php/$PHP_VERSION/fpm/pool.d/www.conf
sed -i -e "s|;ping.response = pong|ping.response = OK|g" /etc/php/$PHP_VERSION/fpm/pool.d/www.conf

### Set PHP memory max
if [ ! -z "$PHP_MEMORY_MAX" ]; then
  sed -i -e "s#memory_limit = 128M#memory_limit = ${PHP_MEMORY_MAX}M#g" /etc/php/$PHP_VERSION/fpm/php.ini
fi
printf "\e[1;34m%-30s\e[m %-30s\n" "PHP Memory Max:" "`php -r 'echo ini_get("memory_limit");'`"

### PHP Opcache
if [ -z "$DISABLE_OPCACHE" ]; then
  # enable opcache
  printf "\e[1;34m%-30s\e[m %-30s\n" "PHP Opcache:" "Enabled"
  sed -i -e "s|;opcache.enable=1|opcache.enable=1|g" /etc/php/$PHP_VERSION/fpm/php.ini
else
  # disable opcache
  printf "\e[1;34m%-30s\e[m %-30s\n" "PHP Opcache:" "Disabled"
  sed -i -e "s#opcache.enable=1#opcache.enable=0#g" /etc/php/$PHP_VERSION/fpm/php.ini
  sed -i -e "s#opcache.enable_cli=1#opcache.enable_cli=0#g" etc/php/$PHP_VERSION/fpm/php.ini
fi
# PHP Opcache Memory
if [ ! -z "$PHP_OPCACHE_MEMORY" ]; then
  # if php_opcache_memory is set
  sed -i -e "s#opcache.memory_consumption=16#opcache.memory_consumption=${PHP_OPCACHE_MEMORY}#g" etc/php/$PHP_VERSION/fpm/php.ini
fi
printf "\e[1;34m%-30s\e[m %-30s\n" "Opcache Memory Max:" "`php -r 'echo ini_get("opcache.memory_consumption");'`M"

###
### Set PHP errors on in QA only.
###
if [ "$ENVIRONMENT" = "production" ]; then
  sed -i "s|display_errors = Off|display_errors = On|" /etc/php/${PHP_VERSION}/cli/php.ini
else
  sed -i "s|display_errors = Off|display_errors = On|" /etc/php/${PHP_VERSION}/cli/php.ini
fi

# PHP Session Config
# If set
if [ ! -z "$PHP_SESSION_STORE" ]; then
    # Figure out which session save handler is in use, currently only supports redis
    if [ $PHP_SESSION_STORE == 'redis' ] || [ $PHP_SESSION_STORE == 'REDIS' ]; then
        if [ -z $PHP_SESSION_STORE_REDIS_HOST ]; then
            PHP_SESSION_STORE_REDIS_HOST='redis'
        fi
        if [ -z $PHP_SESSION_STORE_REDIS_PORT ]; then
            PHP_SESSION_STORE_REDIS_PORT='6379'
        fi
        printf "\e[1;34m%-30s\e[m %-30s\n" "PHP Sessions:" "Redis"
        printf "\e[1;34m%-30s\e[m %-30s\n" "PHP Redis Host:" "$PHP_SESSION_STORE_REDIS_HOST"
        printf "\e[1;34m%-30s\e[m %-30s\n" "PHP Redis Port:" "$PHP_SESSION_STORE_REDIS_PORT"
        sed -i -e "s|session.save_handler = files|session.save_handler = redis\nsession.save_path = \"tcp://$PHP_SESSION_STORE_REDIS_HOST:$PHP_SESSION_STORE_REDIS_PORT\"|g" /etc/php/$PHP_VERSION/fpm/php.ini
    fi
fi
