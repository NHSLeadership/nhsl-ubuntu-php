#!/usr/bin/with-contenv sh

###
### Do we really need this? s6 will only enable cron
### if containerrole = worker
###

# Cron
# If DISABLE_CRON is set:
#if [ ! -z "$DISABLE_CRON" ]; then
#    # Disabled
#    printf "\e[1;34m%-30s\e[m %-30s\n" "Cron:" "Disabled"
#fi

# If not set, enable monitoring:
#if [ -z "$DISABLE_CRON" ]; then
#    # Enabled
#    printf "\e[1;34m%-30s\e[m %-30s\n" "Cron:" "Enabled"
#    cp /etc/supervisor.d/cron.conf /etc/supervisord-enabled/
#fi
