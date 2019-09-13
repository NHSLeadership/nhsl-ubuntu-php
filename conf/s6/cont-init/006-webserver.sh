#!/usr/bin/with-contenv bash

### Set Nginx config
if [ ! -z "$NGINX_PORT" ]; then
  printf "\e[1;34m%-30s\e[m %-30s\n" "Nginx Port:" "$NGINX_PORT"
  sed -i -e "s|listen 80|listen $NGINX_PORT|g" /etc/nginx/sites-enabled/site.conf
else
  printf "\e[1;34m%-30s\e[m %-30s\n" "Nginx Port:" "80"
fi

if [ ! -z "$NGINX_WEB_ROOT" ]; then
  printf "\e[1;34m%-30s\e[m %-30s\n" "Nginx Port:" "$NGINX_PORT"
  sed -i -e "s|root /src/public|root $NGINX_WEB_ROOT|g" /etc/nginx/sites-enabled/site.conf
else
  printf "\e[1;34m%-30s\e[m %-30s\n" "Nginx Root:" "/src/public"
fi

if [ "$HEADER_NOSNIFF" == "false" ]; then
  sed -i -e "s|add_header X-Content-Type-Options nosniff;||g" /etc/nginx/sites-enabled/site.conf
  printf "\e[1;34m%-30s\e[m %-30s\n" "Nginx strict mime checks: " "DISABLED"
fi

if [ "$HEADER_FRAMEOPTS" == "false" ]; then
  sed -i -e "s|add_header X-Frame-Options sameorigin;||g" /etc/nginx/sites-enabled/site.conf
  printf "\e[1;34m%-30s\e[m %-30s\n" "Nginx sameorigin frames: " "DISABLED"
fi
