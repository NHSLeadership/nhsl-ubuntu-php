#!/usr/bin/with-contenv bash

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
            fastcgi_param PHP_VALUE "atatus.enabled=on;";\
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
            fastcgi_param PHP_VALUE \"atatus.enabled=on;\";\
            fastcgi_param PATH_INFO $fastcgi_path_info;\
        }'

NGINX_WORDPRESS='location ~ \.php$ {\
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
            fastcgi_param PHP_VALUE "atatus.enabled=on;";\
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
            fastcgi_param PHP_VALUE "atatus.enabled=on;";\
    }'

if [ "$OSSAPP" == "MOODLE" ]; then
  sed -i -e "s@###phpblock@$NGINX_MOODLE@g" /etc/nginx/sites-enabled/site.conf
  printf "\e[1;34m%-30s\e[m %-30s\n" "Nginx configured for : " "MOODLE"
elif [ "$OSSAPP" == "WORDPRESS" ]; then
  sed -i -e "s@###phpblock@$NGINX_WORDPRESS@g" /etc/nginx/sites-enabled/site.conf
  printf "\e[1;34m%-30s\e[m %-30s\n" "Nginx configured for : " "WORDPRESS"
elif [ "$OSSAPP" == "LARAVEL" ]; then
  sed -i -e "s@###phpblock@$NGINX_LARAVEL@g" /etc/nginx/sites-enabled/site.conf
  printf "\e[1;34m%-30s\e[m %-30s\n" "Nginx configured for : " "LARAVEL"
else
  sed -i -e "s@###phpblock@$NGINX_GENERIC@g" /etc/nginx/sites-enabled/site.conf
  printf "\e[1;34m%-30s\e[m %-30s\n" "Nginx configured for : " "GENERIC PHP APP"
fi
