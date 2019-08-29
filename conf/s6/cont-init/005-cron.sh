#!/usr/bin/with-contenv sh
set -e

###
### Do we really need this? s6 will only enable cron
### if containerrole = worker
###

# Cron
# If DISABLE_CRON is set:
if [ ! -z "$DISABLE_CRON" ]; then
    # Disabled
    printf "%-30s %-30s\n" "Cron:" "Disabled"
fi

# If not set, enable monitoring:
if [ -z "$DISABLE_CRON" ]; then
    # Enabled
    printf "%-30s %-30s\n" "Cron:" "Enabled"
    cp /etc/supervisor.d/cron.conf /etc/supervisord-enabled/
fi