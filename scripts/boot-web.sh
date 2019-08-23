#!/bin/bash
printf "\nStarting Web container...\n\n"

printf "Supervisor starting...\n"
exec /usr/bin/supervisord -n -c /etc/supervisor/supervisord.conf