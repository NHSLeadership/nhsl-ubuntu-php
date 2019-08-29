#!/usr/bin/with-contenv sh
set -e

### Configure Atatus settings
if [ ! -z "$ATATUS_APM_LICENSE_KEY" ]; then
  # If API key set then configure it
  sed -i -e "s/atatus.license_key = \"\"/atatus.license_key = \"$ATATUS_APM_LICENSE_KEY\"/g" /etc/php/$PHP_VERSION/fpm/conf.d/atatus.ini
  sed -i -e "s/atatus.release_stage = \"production\"/atatus.release_stage = \"$ENVIRONMENT\"/g" /etc/php/$PHP_VERSION/fpm/conf.d/atatus.ini
  sed -i -e "s/atatus.app_name = \"PHP App\"/atatus.app_name = \"$SITE_NAME\"/g" /etc/php/$PHP_VERSION/fpm/conf.d/atatus.ini
  sed -i -e "s/atatus.app_version = \"\"/atatus.app_version = \"$SITE_BRANCH-$BUILD\"/g" /etc/php/$PHP_VERSION/fpm/conf.d/atatus.ini
  sed -i -e "s/atatus.tags = \"\"/atatus.tags = \"$SITE_BRANCH-$BUILD, $SITE_BRANCH\"/g" /etc/php/$PHP_VERSION/fpm/conf.d/atatus.ini
  printf "%-30s %-30s\n" "Atatus:" "Enabled"
else
  # Atatus - if api key is not set then disable
  printf "%-30s %-30s\n" "Atatus:" "Disabled"
  rm -f /etc/php/$PHP_VERSION/fpm/conf.d/atatus.ini
fi