#!/usr/bin/with-contenv sh
set -e

### Set Nginx config
if [ ! -z "$NGINX_PORT" ]; then
  printf "\e[1;34m%-30s\e[m %-30s\n" "Nginx Port:" "$NGINX_PORT"
  sed -i -e "s|listen 80|listen $NGINX_PORT|g" /etc/$WEBSRV/nginx.conf
else
  printf "\e[1;34m%-30s\e[m %-30s\n" "Nginx Port:" "80"
fi

if [ ! -z "$NGINX_WEB_ROOT" ]; then
  printf "\e[1;34m%-30s\e[m %-30s\n" "Nginx Port:" "$NGINX_PORT"
  sed -i -e "s|root /src/public|root $NGINX_WEB_ROOT|g" /etc/$WEBSRV/nginx.conf
else
  printf "\e[1;34m%-30s\e[m %-30s\n" "Nginx Root:" "/src/public"
fi

