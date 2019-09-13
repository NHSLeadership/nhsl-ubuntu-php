#!/usr/bin/with-contenv sh

### Configure Atatus settings
if [ ! -z "$ATATUS_APM_LICENSE_KEY" ] && [ "$ENVIRONMENT" == "production" ]; then
  # If API key set then configure Atatus
  sed -i -e 's|atatus.trace.response_time = 2000|atatus.trace.response_time = 1500|g' /etc/php/${PHP_VERSION}/fpm/conf.d/atatus.ini
  sed -i -e 's|atatus.agent.log_file = "/var/log/atatus/agent.log"|atatus.agent.log_file = "/dev/stdout"|g' /etc/php/${PHP_VERSION}/fpm/conf.d/atatus.ini
  sed -i -e 's|atatus.collector.log_file = "/var/log/atatus/collector.log"|atatus.collector.log_file = "/dev/stdout"|g' /etc/php/${PHP_VERSION}/fpm/conf.d/atatus.ini
  sed -i -e "s/atatus.license_key = \"\"/atatus.license_key = \"$ATATUS_APM_LICENSE_KEY\"/g" /etc/php/$PHP_VERSION/fpm/conf.d/atatus.ini
  sed -i -e "s/atatus.release_stage = \"production\"/atatus.release_stage = \"$ENVIRONMENT\"/g" /etc/php/$PHP_VERSION/fpm/conf.d/atatus.ini
  sed -i -e "s/atatus.app_name = \"PHP App\"/atatus.app_name = \"$SITE_NAME\"/g" /etc/php/$PHP_VERSION/fpm/conf.d/atatus.ini
  sed -i -e "s/atatus.app_version = \"\"/atatus.app_version = \"$SITE_BRANCH-$BUILD\"/g" /etc/php/$PHP_VERSION/fpm/conf.d/atatus.ini
  sed -i -e "s/atatus.tags = \"\"/atatus.tags = \"$SITE_BRANCH-$BUILD, $SITE_BRANCH\"/g" /etc/php/$PHP_VERSION/fpm/conf.d/atatus.ini
  printf "\e[1;34m%-30s\e[m %-30s\n" "Atatus:" "Enabled"
else
  # Atatus - if api key is not set then disable
  printf "\e[1;34m%-30s\e[m %-30s\n" "Atatus:" "Disabled"
  rm -f /etc/php/$PHP_VERSION/fpm/conf.d/atatus.ini
fi
