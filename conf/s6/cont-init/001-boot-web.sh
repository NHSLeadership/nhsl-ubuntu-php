#!/usr/bin/with-contenv bash
set -e

printf "\033[1;34m    _   ____  _______   _        _
   / | / / / / / ___/  | |      / \   
  /  |/ / /_/ /\__ \   | |     / _ \  
 / /|  / __  /___/ /   | |___ / ___ \ 
/_/ |_/_/ /_//____/    |_____/_/   \_\ \033[0m\n\n"
printf "Entered container environment...\n\n"

# Container info:
printf "\e[1;34m%-30s\e[m %-30s\n" "Site:" "$SITE_NAME"
printf "\e[1;34m%-30s\e[m %-30s\n" "Branch:" "$SITE_BRANCH"
printf "\e[1;34m%-30s\e[m %-30s\n" "Environment:" "$ENVIRONMENT"
printf "\e[1;34m%-30s\e[m %-30s\n" "Role: " "$CONTAINERROLE"
printf "\e[1;34m%-30s\e[m %-30s\n" "OS: " "`lsb_release -ds 2>/dev/null || cat /etc/*release 2>/dev/null | head -n1 || uname -m`"
printf "\e[1;34m%-30s\e[m %-30s\n" "PHP Version:" "`php -r 'echo phpversion();'`"
if [ "$WEBSRV" == "nginx" ]; then
    printf "\e[1;34m%-30s\e[m %-30s\n" "Nginx Version:" "`/usr/sbin/nginx -v 2>&1 | sed -e 's/nginx version: nginx\///g'`"
fi
if [ "$WEBSRV" == "openresty" ]; then
    printf "\e[1;34m%-30s\e[m %-30s\n" "OpenResty Version:" "`/usr/bin/openresty -v 2>&1 | sed -e 's/nginx version: nginx\///g'`"
fi

# if CONTAINERROLE isn't set let's assume web
if [ -z "$CONTAINERROLE" ]; then
  export CONTAINERROLE=web
fi
