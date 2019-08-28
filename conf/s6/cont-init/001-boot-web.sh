#!/usr/bin/with-contenv sh
set -e

printf "\033[1;34m    _   ____  _______   _        _
   / | / / / / / ___/  | |      / \   
  /  |/ / /_/ /\__ \   | |     / _ \  
 / /|  / __  /___/ /   | |___ / ___ \ 
/_/ |_/_/ /_//____/    |_____/_/   \_\ \033[0m\n\n"
printf "Entered container environment...\n\n"

# Container info:
printf "%-30s %-30s\n" "Site:" "$SITE_NAME"
printf "%-30s %-30s\n" "Branch:" "$SITE_BRANCH"
printf "%-30s %-30s\n" "Environment:" "$ENVIRONMENT"
printf "%-30s %-30s\n" "Role: " "$CONTAINERROLE"

printf "%-30s %-30s\n" "PHP Version:" "`php -r 'echo phpversion();'`"
printf "%-30s %-30s\n" "Nginx Version:" "`/usr/sbin/nginx -v 2>&1 | sed -e 's/nginx version: nginx\///g'`"

###
### Configure Atatus settings
###
if [ ! -z "$ATATUS_APM_LICENSE_KEY" ]; then
  printf "%-30s %-30s\n" "Atatus:" "Enabled"
  sed -i -e "s/atatus.license_key = \"\"/atatus.license_key = \"$ATATUS_APM_LICENSE_KEY\"/g" /etc/php/$PHP_VERSION/fpm/conf.d/atatus.ini
  sed -i -e "s/atatus.release_stage = \"production\"/atatus.release_stage = \"$ENVIRONMENT\"/g" /etc/php/$PHP_VERSION/fpm/conf.d/atatus.ini
  sed -i -e "s/atatus.app_name = \"PHP App\"/atatus.app_name = \"$SITE_NAME\"/g" /etc/php/$PHP_VERSION/fpm/conf.d/atatus.ini
  sed -i -e "s/atatus.app_version = \"\"/atatus.app_version = \"$SITE_BRANCH-$BUILD\"/g" /etc/php/$PHP_VERSION/fpm/conf.d/atatus.ini
  sed -i -e "s/atatus.tags = \"\"/atatus.tags = \"$SITE_BRANCH-$BUILD, $SITE_BRANCH\"/g" /etc/php/$PHP_VERSION/fpm/conf.d/atatus.ini
else
  # Atatus - if api key is not set then disable
  printf "%-30s %-30s\n" "Atatus:" "Disabled"
  rm -f /etc/php/$PHP_VERSION/fpm/conf.d/atatus.ini
fi

###
### Set PHP memory max
###
if [ ! -z "$PHP_MEMORY_MAX" ]; then
  sed -i -e "s#memory_limit = 128M#memory_limit = ${PHP_MEMORY_MAX}M#g" /etc/php/$PHP_VERSION/fpm/php.ini
fi
printf "%-30s %-30s\n" "PHP Memory Max:" "`php -r 'echo ini_get("memory_limit");'`"

###
### PHP Opcache 
###
if [ -z "$DISABLE_OPCACHE" ]; then
  # enable opcache
  printf "%-30s %-30s\n" "PHP Opcache:" "Enabled"
  sed -i -e "s|;opcache.enable=1|opcache.enable=1|g" /etc/php/$PHP_VERSION/fpm/php.ini
else
  # disable opcache
  printf "%-30s %-30s\n" "PHP Opcache:" "Disabled"
  sed -i -e "s#opcache.enable=1#opcache.enable=0#g" /etc/php/$PHP_VERSION/fpm/php.ini
  sed -i -e "s#opcache.enable_cli=1#opcache.enable_cli=0#g" etc/php/$PHP_VERSION/fpm/php.ini

fi

# PHP Opcache Memory
# If set
if [ ! -z "$PHP_OPCACHE_MEMORY" ]; then
    sed -i -e "s#opcache.memory_consumption=16#opcache.memory_consumption=${PHP_OPCACHE_MEMORY}#g" etc/php/$PHP_VERSION/fpm/php.ini
fi
printf "%-30s %-30s\n" "Opcache Memory Max:" "`php -r 'echo ini_get("opcache.memory_consumption");'`M"

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
        printf "%-30s %-30s\n" "PHP Sessions:" "Redis"
        printf "%-30s %-30s\n" "PHP Redis Host:" "$PHP_SESSION_STORE_REDIS_HOST"
        printf "%-30s %-30s\n" "PHP Redis Port:" "$PHP_SESSION_STORE_REDIS_PORT"
        sed -i -e "s|session.save_handler = files|session.save_handler = redis\nsession.save_path = \"tcp://$PHP_SESSION_STORE_REDIS_HOST:$PHP_SESSION_STORE_REDIS_PORT\"|g" /etc/php/$PHP_VERSION/fpm/php.ini
    fi
fi

# Cron
# If DISABLE_CRON is set:
if [ ! -z "$DISABLE_CRON" ]; then
    # Disabled
    printf "%-30s %-30s\n" "Cron:" "Disabled"
fi

# If not set, enable monitoring:
if [ -z "$DISABLE_CRON" ]; then

    # Enabled
    printf "%-30s %-30s\n" "Cron:" "Enabled"

    cp /etc/supervisor.d/cron.conf /etc/supervisord-enabled/

fi

# Set SMTP settings
if [ $ENVIRONMENT == 'production' ]; then
    
    if [ -z "$MAIL_HOST" ]; then
        export MAIL_HOST=master-smtp.smtp-production
    fi

    if [ -z "$MAIL_PORT" ]; then
        export MAIL_PORT=25
    fi

fi

if [ $ENVIRONMENT == 'qa' ]; then
    
    if [ -z "$MAIL_HOST" ]; then
        export MAIL_HOST=master-smtp.mailhog-production
    fi
fi

if [ -z "$MAIL_DRIVER" ]; then
    export MAIL_DRIVER=mail
fi

if [ -z "$MAIL_PORT" ]; then
    export MAIL_PORT=25
fi

printf "%-30s %-30s\n" "SMTP:" "$MAIL_HOST:$MAIL_PORT"
sed -i -e "s#sendmail_path = /usr/sbin/sendmail -t -i#sendmail_path = /usr/sbin/sendmail -t -i -S $MAIL_HOST:$MAIL_PORT#g" /etc/php/php.ini

# Startup scripts
if [ -f /startup-all.sh ]; then
    printf "%-30s %-30s\n" "Startup Script:" "Running"
    chmod +x /startup-all.sh && ./startup-all.sh
fi

if [ -f /startup-worker.sh ]; then
    printf "%-30s %-30s\n" "Worker Startup Script:" "Running"
    chmod +x /startup-worker.sh && ./startup-worker.sh
fi


###
### Scripts that should only run on web containers
###
#if [ "$CONTAINERROLE" = "web" ]; then
#fi

###
### Scripts that should only run on worker containers
###
#if [ "$CONTAINERROLE" = "worker" ]; then
#fi