#!/usr/bin/with-contenv sh
set -e

# Set SMTP settings
if [ "$ENVIRONMENT" == "production" ]; then
    if [ -z "$MAIL_HOST" ]; then
        export MAIL_HOST=master-smtp.smtp-production
    fi
    if [ -z "$MAIL_PORT" ]; then
        export MAIL_PORT=25
    fi
fi

if [ "$ENVIRONMENT" == "qa" ]; then
    if [ -z "$MAIL_HOST" ]; then
        export MAIL_HOST=master-smtp.mailhog-production
    fi
fi

if [ -z "$MAIL_DRIVER" ]; then
    export MAIL_DRIVER=mail
fi

if [ -z "$MAIL_PORT" ]; then
    export MAIL_PORT=25
fi

printf "\e[1;34m%-30s\e[m %-30s\n" "SMTP:" "$MAIL_HOST:$MAIL_PORT"
sed -i -e "s|sendmail_path = /usr/sbin/sendmail -t -i|sendmail_path = /usr/sbin/sendmail -t -i -S $MAIL_HOST:$MAIL_PORT|g" /etc/php/$PHP_VERSION/fpm/php.ini
