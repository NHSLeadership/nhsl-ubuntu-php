#!/usr/bin/with-contenv bash

# Set SMTP settings
if [ "$ENVIRONMENT" == "production" ]; then
    if [ -z "$MAIL_HOST" ]; then
        export MAIL_HOST=master-smtp.smtp-production
    fi
    if [ -z "$MAIL_PORT" ]; then
        export MAIL_PORT=25
    fi
fi

# if in QA
if [ "$ENVIRONMENT" == "qa" ]; then
    if [ -z "$MAIL_HOST" ]; then
        export MAIL_HOST=master-smtp.mailhog-production
    fi
fi

# Do a quick check to see if were using an Amazon SQL DB, means were in AWS
## TODO: Remove once GCP is finished
if [[ "$DB_HOST" == *"eu-west-2.rds.amazonaws.com"* ]]; then
    # if were in Production
    if [ "$ENVIRONMENT" == "production" ]; then
        if [ -z "$MAIL_HOST" ]; then
           export MAIL_HOST=smtp.kube-mail
       fi
    fi
    
    # if were in staging
    # TODO: Once we have kbuild v2 we'll remove SMTP external sending from Staging entirely
    ## and MAIL_HOST will always be smtp.kube-mail
    if [ "$ENVIRONMENT" == "staging" ]; then
        if [ -z "$MAIL_HOST" ]; then
           export MAIL_HOST=mailhog.kube-mail
       fi
    fi
fi

if [ -z "$MAIL_DRIVER" ]; then
    export MAIL_DRIVER=mail
fi

if [ -z "$MAIL_PORT" ]; then
    export MAIL_PORT=25
fi

echo "mailhub=$MAIL_HOST:$MAIL_PORT" >> /etc/ssmtp/ssmtp.conf
echo "root=devops@nhsx.uk" >> /etc/ssmtp/ssmtp.conf
echo "FromLineOverride=YES" >> /etc/ssmtp/ssmtp.conf
printf " %-30s %-30s\n" "SMTP: " "$MAIL_HOST:$MAIL_PORT"
sed -i -e "s|;sendmail_path =|sendmail_path = /usr/sbin/ssmtp -t|g" /etc/php/$PHP_VERSION/fpm/php.ini
