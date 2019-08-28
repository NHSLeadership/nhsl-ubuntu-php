#!/usr/bin/with-contenv sh
set -e

printf "%-30s %-30s\n" "PHP Version:" "`php -r 'echo phpversion();'`"
printf "%-30s %-30s\n" "Nginx Version:" "`/usr/sbin/nginx -v 2>&1 | sed -e 's/nginx version: nginx\///g'`"

###
### Configure Atatus settings
###
if [ ! -z "$ATATUS_APM_LICENSE_KEY" ]; then
    printf "%-30s %-30s\n" "Atatus:" "Enabled"
    # Set the atatus api key
    sed -i -e "s/atatus.license_key = \"\"/atatus.license_key = \"$ATATUS_APM_LICENSE_KEY\"/g" /etc/php/$PHP_VERSION/fpm/conf.d/atatus.ini
    # Set the release stage to be the environment
    sed -i -e "s/atatus.release_stage = \"production\"/atatus.release_stage = \"$ENVIRONMENT\"/g" /etc/php/$PHP_VERSION/fpm/conf.d/atatus.ini
    # Set the app name to be site_name environment
    sed -i -e "s/atatus.app_name = \"PHP App\"/atatus.app_name = \"$SITE_NAME\"/g" /etc/php/$PHP_VERSION/fpm/conf.d/atatus.ini
    # Set the app version to be the branch build
    sed -i -e "s/atatus.app_version = \"\"/atatus.app_version = \"$SITE_BRANCH-$BUILD\"/g" /etc/php/$PHP_VERSION/fpm/conf.d/atatus.ini
    # Set the tags to contain useful data
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
    # Set PHP.ini accordingly
    sed -i -e "s#memory_limit = 128M#memory_limit = ${PHP_MEMORY_MAX}M#g" /etc/php/$PHP_VERSION/fpm/php.ini
fi
printf "%-30s %-30s\n" "PHP Memory Max:" "`php -r 'echo ini_get("memory_limit");'`"

###
### PHP Opcache 
###
if [ -z "$DISABLE_OPCACHE" ]; then
    # not set
    printf "%-30s %-30s\n" "PHP Opcache:" "Enabled"
else
    # is set    
    printf "%-30s %-30s\n" "PHP Opcache:" "Disabled"
    sed -i -e "s#opcache.enable=1#opcache.enable=0#g" /etc/php/$PHP_VERSION/fpm/php.ini
    sed -i -e "s#opcache.enable_cli=1#opcache.enable_cli=0#g" etc/php/$PHP_VERSION/fpm/php.ini

fi

# PHP Opcache Memory
# If set
if [ ! -z "$PHP_OPCACHE_MEMORY" ]; then
    # Set PHP.ini accordingly
    sed -i -e "s#opcache.memory_consumption=16#opcache.memory_consumption=${PHP_OPCACHE_MEMORY}#g" etc/php/$PHP_VERSION/fpm/php.ini
fi
# Print the real value
printf "%-30s %-30s\n" "Opcache Memory Max:" "`php -r 'echo ini_get("opcache.memory_consumption");'`M"

###
### Set PHP errors on in QA only.
###
if [ "$ENVIRONMENT" = "production" ]; then
  sed -i "s|display_errors = Off|display_errors = On|" /etc/php/${PHP_VERSION}/cli/php.ini
else
  sed -i "s|display_errors = Off|display_errors = On|" /etc/php/${PHP_VERSION}/cli/php.ini && \
fi

###
### Scripts that should only run on web containers
###
if [ "$CONTAINERROLE" = "web" ]; then

fi

###
### Scripts that should only run on worker containers
###
if [ "$CONTAINERROLE" = "worker" ]; then

fi