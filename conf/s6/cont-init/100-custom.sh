#!/usr/bin/with-contenv sh
set -e

# If the user wants to add some custom scripts to run at container runtime
# then we allow them to do it here, once everything else is bootstrapped but
# before the application is running.

if [ -f /startup-all.sh ]; then
    printf "%-30s %-30s\n" "Startup Script:" "Running"
    chmod +x /startup-all.sh && ./startup-all.sh
fi

if [ -f /startup-web.sh ] && [ "$CONTAINERROLE" == "web" ]; then
    printf "%-30s %-30s\n" "Startup Script:" "Running"
    chmod +x /startup-web.sh && ./startup-web.sh
fi

if [ -f /startup-worker.sh ] && [ "$CONTAINERROLE" == "worker"]; then
    printf "%-30s %-30s\n" "Worker Startup Script:" "Running"
    chmod +x /startup-worker.sh && ./startup-worker.sh
fi