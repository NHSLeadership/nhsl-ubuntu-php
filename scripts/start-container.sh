#!/bin/bash

printf "\033    _   ____  _______   _        _
   / | / / / / / ___/  | |      / \   
  /  |/ / /_/ /\__ \   | |     / _ \  
 / /|  / __  /___/ /   | |___ / ___ \ 
/_/ |_/_/ /_//____/    |_____/_/   \_\ \033\n\n"
printf "Entered container environment...\n\n"
printf "NHS Leadership Academy\n\n"
printf " %-30s %-30s\n" "Base build date: " "`cat /build_image_date`"
printf " %-30s %-30s\n" "Site build date: " "`cat /build_site_date`"

# Container info:
printf " %-30s %-30s\n" "Site:" "$SITE_NAME"
printf " %-30s %-30s\n" "Branch:" "$SITE_BRANCH"
printf " %-30s %-30s\n" "Environment:" "$ENVIRONMENT"
printf " %-30s %-30s\n" "Role: " "$CONTAINERROLE"
printf " %-30s %-30s\n" "OS: " "`lsb_release -ds 2>/dev/null || cat /etc/*release 2>/dev/null | head -n1 || uname -m`"
printf " %-30s %-30s\n" "PHP Version: " "`php -r 'echo phpversion();'`"
printf " %-30s %-30s\n" "Nginx Version: " "`/usr/sbin/nginx -v 2>&1 | sed -e 's/nginx version: nginx\///g'`"

# if CONTAINERROLE isn't set let's assume web
if [ -z "$CONTAINERROLE" ]; then
  export CONTAINERROLE=web
fi

# if we're on web then we remove the cron service
if [ "$CONTAINERROLE" == "web" ]; then
  echo " Running a WEB pod so removing cron service from supervisor..."
  rm -rf /etc/supervisor/conf.d/cron.conf
fi

# if we're on a worker then we remove the nginx and php services
if [ "$CONTAINERROLE" == "worker" ]; then
  echo " Running a WORKER pod so removing Nginx and PHP services from supervisor..."
  rm -rf /etc/supervisor/conf.d/nginx.conf
  rm -rf /etc/supervisor/conf.d/php-fpm.conf
  rm /etc/cron.d/php
  mkdir -p /var/spool/cron
fi

###
# Email configuration
###
# Do a quick check to see if were using an Amazon SQL DB, means were in AWS
## TODO: Remove once GCP is finished
if [ -z "$MAIL_HOST" ]; then
  if [[ "$DB_HOST" == *"eu-west-2.rds.amazonaws.com"* ]]; then
      # if were in Production
      if [ "$ENVIRONMENT" == "production" ]; then
         export MAIL_HOST=smtp.kube-mail
      fi

      # if were in staging
      if [ "$ENVIRONMENT" == "staging" ]; then
         export MAIL_HOST=mailhog.kube-mail
      fi
  else
    # if GCP Production
    if [ "$ENVIRONMENT" == "production" ]; then
        export MAIL_HOST=master-smtp.smtp-production
    fi

    # if GCP QA
    if [ "$ENVIRONMENT" == "qa" ]; then
        export MAIL_HOST=master-smtp.mailhog-production
    fi
  fi
fi

if [ -z "$MAIL_DRIVER" ]; then
    export MAIL_DRIVER=mail
fi

if [ -z "$MAIL_PORT" ]; then
    export MAIL_PORT=25
fi

echo "mailhub=$MAIL_HOST:$MAIL_PORT" >> /etc/ssmtp/ssmtp.conf
echo "root=devops@nhsx.uk" >> /etc/ssmtp/ssmtp.conf
echo "FromLineOverride=YES" >> /etc/ssmtp/ssmtp.conf
printf " %-30s %-30s\n" "SMTP: " "$MAIL_HOST:$MAIL_PORT"
sed -i -e "s|;sendmail_path =|sendmail_path = /usr/sbin/ssmtp -t|g" /etc/php/$PHP_VERSION/fpm/php.ini
###
# END mail configuration
###

###
# PHP Configuration
###
### Set PHP memory max
if [ ! -z "$PHP_MEMORY_MAX" ]; then
  sed -i -e "s#memory_limit = 128M#memory_limit = ${PHP_MEMORY_MAX}M#g" /etc/php/$PHP_VERSION/fpm/php.ini
fi
printf " %-30s %-30s\n" "PHP Memory Max:" "`php -r 'echo ini_get("memory_limit");'`"

### PHP Opcache
if [ -z "$DISABLE_OPCACHE" ]; then
  # enable opcache
  printf " %-30s %-30s\n" "PHP Opcache:" "Enabled"
  sed -i -e "s|;opcache.enable=1|opcache.enable=1|g" /etc/php/$PHP_VERSION/fpm/php.ini
else
  # disable opcache
  printf " %-30s %-30s\n" "PHP Opcache:" "Disabled"
  sed -i -e "s#opcache.enable=1#opcache.enable=0#g" /etc/php/$PHP_VERSION/fpm/php.ini
  sed -i -e "s#opcache.enable_cli=1#opcache.enable_cli=0#g" /etc/php/$PHP_VERSION/fpm/php.ini
fi
### PHP Opcache Memory
if [ ! -z "$PHP_OPCACHE_MEMORY" ]; then
  # if php_opcache_memory is set
  sed -i -e "s#opcache.memory_consumption=16#opcache.memory_consumption=${PHP_OPCACHE_MEMORY}#g" /etc/php/$PHP_VERSION/fpm/php.ini
fi
printf " %-30s %-30s\n" "Opcache Memory Max: " "`php -r 'echo ini_get("opcache.memory_consumption");'`M"

###
### Set PHP errors on in QA only.
###
if [ "$ENVIRONMENT" != "production" ]; then
  sed -i "s|display_errors = Off|display_errors = On|" /etc/php/${PHP_VERSION}/cli/php.ini
fi

# PHP Session Config
# If set
if [ ! -z "$PHP_SESSION_STORE" ]; then
    # Figure out which session save handler is in use, currently only supports redis
    if [ "$PHP_SESSION_STORE" == "REDIS" ] || [ "$PHP_SESSION_STORE" == "redis" ]; then
        if [ -z "$PHP_SESSION_STORE_REDIS_HOST" ]; then
            PHP_SESSION_STORE_REDIS_HOST='redis'
        fi
        if [ -z "$PHP_SESSION_STORE_REDIS_PORT" ]; then
            PHP_SESSION_STORE_REDIS_PORT='6379'
        fi
        printf " %-30s %-30s\n" "PHP Sessions: " "Redis"
        printf " %-30s %-30s\n" "PHP Redis Host: " "$PHP_SESSION_STORE_REDIS_HOST"
        printf " %-30s %-30s\n" "PHP Redis Port: " "$PHP_SESSION_STORE_REDIS_PORT"
        sed -i -e "s|session.save_handler = files|session.save_handler = redis\nsession.save_path = \"tcp://$PHP_SESSION_STORE_REDIS_HOST:$PHP_SESSION_STORE_REDIS_PORT\"|g" /etc/php/$PHP_VERSION/fpm/php.ini
    fi
fi
###
# END PHP Configuration
###


###
# Nginx Configuration
###
### Set Nginx config
if [ ! -f /startup-nginx.conf ]; then
  printf " %-30s %-30s\n" "Customising Nginx: " "Yes, no overriding config found."
  if [ ! -z "$NGINX_PORT" ]; then
    printf " %-30s %-30s\n" "Nginx Port: " "$NGINX_PORT"
    sed -i -e "s|listen 80|listen $NGINX_PORT|g" /etc/nginx/sites-enabled/site.conf
  else
    printf " %-30s %-30s\n" "Nginx Port: " "80"
  fi

  if [ ! -z "$NGINX_WEB_ROOT" ]; then
    printf " %-30s %-30s\n" "Nginx Root: " "$NGINX_WEB_ROOT"
    sed -i -e "s|root /src/public|root $NGINX_WEB_ROOT|g" /etc/nginx/sites-enabled/site.conf
  else
    printf " %-30s %-30s\n" "Nginx Root:" "/src/public"
  fi

  if [ "$HEADER_NOSNIFF" == "false" ]; then
    sed -i -e "s|add_header X-Content-Type-Options nosniff;||g" /etc/nginx/sites-enabled/site.conf
    printf " %-30s %-30s\n" "Nginx strict mime checks: " "DISABLED"
  fi

  if [ "$HEADER_FRAMEOPTS" == "false" ]; then
    sed -i -e "s|add_header X-Frame-Options sameorigin;||g" /etc/nginx/sites-enabled/site.conf
    printf " %-30s %-30s\n" "Nginx sameorigin frames: " "DISABLED"
  fi
else
  cp /startup-nginx.conf /etc/nginx/nginx.conf
  printf " %-30s %-30s\n" "Customised Nginx config: " "DISABLED. Found /startup-nginx.conf which overrides these."
fi
###
# END Nginx Configuration
###

###
# Predefined application configurations
###
NGINX_GENERIC='location ~ \.php$ {\
            try_files $uri =404;\
            include fastcgi_params;\
            fastcgi_split_path_info ^(.+\.php)(/.+)$;\
            fastcgi_pass unix:/var/run/php-fpm.sock;\
            fastcgi_param SERVER_NAME $http_host;\
            fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;\
            fastcgi_param SCRIPT_NAME $fastcgi_script_name;\
            fastcgi_index index.php;\
            fastcgi_read_timeout 600s;\
            fastcgi_request_buffering off;\
            fastcgi_param PHP_VALUE "atatus.enabled=true;";\
        }'

NGINX_MOODLE='location ~ [^/]\.php(/|$) {\
            fastcgi_split_path_info ^(.+\.php)(/.+)$;\
            fastcgi_pass unix:/var/run/php-fpm.sock;\
            fastcgi_param SERVER_NAME $http_host;\
            fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;\
            fastcgi_param SCRIPT_NAME $fastcgi_script_name;\
            fastcgi_index index.php;\
            fastcgi_read_timeout 600s;\
            include fastcgi_params;\
            fastcgi_param PATH_INFO $fastcgi_path_info;\
            fastcgi_param PHP_VALUE "atatus.enabled=true;";\
        }'

NGINX_WORDPRESS='location / {\
        try_files $uri $uri/ /index.php?$query_string;\
    }\
    location ~ \.php$ {\
            try_files $uri =404;\
            include fastcgi_params;\
            fastcgi_split_path_info ^(.+\.php)(/.+)$;\
            fastcgi_pass unix:/var/run/php-fpm.sock;\
            fastcgi_param SERVER_NAME $http_host;\
            fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;\
            fastcgi_param SCRIPT_NAME $fastcgi_script_name;\
            fastcgi_index index.php;\
            fastcgi_read_timeout 600s;\
            fastcgi_request_buffering off;\
            fastcgi_param PHP_VALUE "atatus.enabled=true;";\
    }'

NGINX_LARAVEL='location / {\
        try_files $uri $uri/ /index.php?$query_string;\
    }
    location ~ \.php$ {\
            try_files $uri =404;\
            include fastcgi_params;\
            fastcgi_split_path_info ^(.+\.php)(/.+)$;\
            fastcgi_pass unix:/var/run/php-fpm.sock;\
            fastcgi_param SERVER_NAME $http_host;\
            fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;\
            fastcgi_param SCRIPT_NAME $fastcgi_script_name;\
            fastcgi_index index.php;\
            fastcgi_read_timeout 600s;\
            fastcgi_request_buffering off;\
            fastcgi_param PHP_VALUE "atatus.enabled=true;";\
    }'

if [ "$OSSAPP" == "MOODLE" ]; then
  sed -i -e "s@###phpblock@$NGINX_MOODLE@g" /etc/nginx/sites-enabled/site.conf
  printf " %-30s %-30s\n" "Nginx configured for: " "MOODLE"
elif [ "$OSSAPP" == "WORDPRESS" ]; then
  sed -i -e "s@###phpblock@$NGINX_WORDPRESS@g" /etc/nginx/sites-enabled/site.conf
  printf " %-30s %-30s\n" "Nginx configured for: " "WORDPRESS"
elif [ "$OSSAPP" == "LARAVEL" ]; then
  sed -i -e "s@###phpblock@$NGINX_LARAVEL@g" /etc/nginx/sites-enabled/site.conf
  printf " %-30s %-30s\n" "Nginx configured for: " "LARAVEL"
else
  sed -i -e "s@###phpblock@$NGINX_GENERIC@g" /etc/nginx/sites-enabled/site.conf
  printf " %-30s %-30s\n" "Nginx configured for: " "GENERIC PHP APP"
fi
###
# END Predefined application configurations
###

###
# Configure Atatus
###
if [ ! -z "$ATATUS_APM_LICENSE_KEY" ]; then
  # If API key set then configure Atatus
  sed -i -e "s/atatus.license_key = \"\"/atatus.license_key = \"$ATATUS_APM_LICENSE_KEY\"/g" /etc/php/$PHP_VERSION/fpm/conf.d/atatus.ini
  sed -i -e "s/atatus.release_stage = \"production\"/atatus.release_stage = \"$ENVIRONMENT\"/g" /etc/php/$PHP_VERSION/fpm/conf.d/atatus.ini
  sed -i -e "s/atatus.app_name = \"PHP App\"/atatus.app_name = \"$SITE_NAME\"/g" /etc/php/$PHP_VERSION/fpm/conf.d/atatus.ini
  sed -i -e "s/atatus.app_version = \"\"/atatus.app_version = \"$SITE_BRANCH-$BUILD\"/g" /etc/php/$PHP_VERSION/fpm/conf.d/atatus.ini
  sed -i -e "s/atatus.tags = \"\"/atatus.tags = \"$SITE_BRANCH-$BUILD, $SITE_BRANCH\"/g" /etc/php/$PHP_VERSION/fpm/conf.d/atatus.ini
  printf " %-30s %-30s\n" "Atatus:" "Enabled"
else
  # Atatus - if api key is not set then disable
  printf " %-30s %-30s\n" "Atatus: " "Disabled"
  rm -f /etc/php/$PHP_VERSION/fpm/conf.d/atatus.ini
fi
###
# END Atatus configuration
###

###
# Run custom scripts if they exist
###
if [ -f /startup-all.sh ]; then
    printf " %-30s %-30s\n" "Startup Script: " "Running"
    chmod a+x /startup-all.sh && /./startup-all.sh
else
    printf " %-30s %-30s\n" "Startup Script: " "/startup-all.sh NOT found. That's probably OK..."
fi

if [ -f /startup-web.sh ] && [ "$CONTAINERROLE" == "web" ]; then
    printf " %-30s %-30s\n" "Startup Script: " "Running"
    chmod a+x /startup-web.sh && /./startup-web.sh
else
    printf " %-30s %-30s\n" "Startup Script: " "/startup-web.sh NOT found. That's probably OK..."
fi

if [ -f /startup-worker.sh ] && [ "$CONTAINERROLE" == "worker" ]; then
    printf " %-30s %-30s\n" "Worker Startup Script: " "Running"
    chmod a+x /startup-worker.sh && /./startup-worker.sh
else
    printf " %-30s %-30s\n" "Startup Script: " "/startup-worker.sh NOT found. That's probably OK..."
fi

if [ -f /startup-nginx.conf ]; then
  printf " %-30s %-30s\n" "Custom Nginx conf: " "Copied"
  cp -fs /etc/nginx/sites-enabled/site.conf
else
  printf " %-30s %-30s\n" "Custom Nginx conf: " "Not found, using default."
fi
###
# END Custom script runs
###

###
# Dumping environment variables
###
printenv | sed 's/^\(.*\)$/export \1/g' >> /etc/profile.d/docker_env.sh

###
# RUN THE CONTAINER
###
printf " %-30s\n" "Starting supervisord"

# Start supervisord and services
exec /usr/bin/supervisord -n -c /etc/supervisord.conf
