#!/usr/bin/with-contenv bash

if [ ! -z "$OLD_DOMAINS" ]; then
  IFS=','
  read -a strarr <<< "$OLD_DOMAINS"

  for i in ${OLD_DOMAINS[@]}; do
    sed -i -e "s@###domainredirect@if (\$http_host = \"$i\") {\n        rewrite ^ https://$DOMAIN\$request_uri permanent;\n    }\n    ###domainredirect@g" /etc/nginx/sites-enabled/site.conf
    #sed -i -e "s@###domainredirect@rewrite ^(.*)$i/(.*)$ https://$DOMAIN/$2 permanent;\n###domainredirect@g" /etc/nginx/sites-enabled/site.conf
  done
fi