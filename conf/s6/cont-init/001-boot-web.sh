#!/usr/bin/with-contenv bash

printf "\033    _   ____  _______   _        _
   / | / / / / / ___/  | |      / \   
  /  |/ / /_/ /\__ \   | |     / _ \  
 / /|  / __  /___/ /   | |___ / ___ \ 
/_/ |_/_/ /_//____/    |_____/_/   \_\ \033\n\n"
printf "Entered container environment...\n\n"

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

if [ "$CONTAINERROLE" == "web" ]; then
  rm -rf /etc/services.d/cron
  rm -rf /etc/services.d/cronlog
fi

if [ "$CONTAINERROLE" == "worker" ]; then
  echo "Running a worker pod so removing Nginx and PHP-FPM services..."
  rm -rf /etc/services.d/nginx
  rm -rf /etc/services.d/php-fpm
  
  # this line here is what we should have to get rid of the hard link error with crond
  # put env vars into /etc/environment so Cron will read them automatically
  # TODO: find a better way of doing this.
  touch /etc/crontab /etc/cron.*/*
  env > /etc/environment
fi