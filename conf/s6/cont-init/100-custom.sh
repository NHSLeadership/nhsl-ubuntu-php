#!/usr/bin/with-contenv bash

# If the user wants to add some custom scripts to run at container runtime
# then we allow them to do it here, once everything else is bootstrapped but
# before the application is running.

if [ -f /startup-all.sh ]; then
    printf "\e[1;34m%-30s\e[m %-30s\n" "Startup Script:" "Running"
    chmod a+x /startup-all.sh && /./startup-all.sh
else
    printf "\e[1;34m%-30s\e[m %-30s\n" "Startup Script:" "/startup-all.sh NOT found. That's probably OK..."
fi

if [ -f /startup-web.sh ] && [ "$CONTAINERROLE" == "web" ]; then
    printf "\e[1;34m%-30s\e[m %-30s\n" "Startup Script:" "Running"
    chmod a+x /startup-web.sh && /./startup-web.sh
else
    printf "\e[1;34m%-30s\e[m %-30s\n" "Startup Script:" "/startup-web.sh NOT found. That's probably OK..."
fi

if [ -f /startup-worker.sh ] && [ "$CONTAINERROLE" == "worker" ]; then
    printf "\e[1;34m%-30s\e[m %-30s\n" "Worker Startup Script:" "Running"
    chmod a+x /startup-worker.sh && /./startup-worker.sh
else
    printf "\e[1;34m%-30s\e[m %-30s\n" "Startup Script:" "/startup-worker.sh NOT found. That's probably OK..."
fi

if [ -f /startup-nginx.conf ]; then
  printf "\e[1;34m%-30s\e[m %-30s\n" "Custom Nginx conf:" "Copied"
  cp -fs /etc/nginx/sites-enabled/site.conf
else
  printf "\e[1;34m%-30s\e[m %-30s\n" "Custom Nginx conf:" "Not found, using default."