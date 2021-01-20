# nhsl-ubuntu-php

A Docker image for NHS Leadership Academy based on Ubuntu Bionic.

This provides Nginx, PHP, and an array of commonly used tools. It aims to be an image capable of running production environments whilst still being easy to work with.

## Building
This image needs some Docker --build-arg statements to be able to build successfully.

| Argument     | Values                        | Comments                             |
| ------------ | ----------------------------- | ------------------------------------ |
| PHPV         | `7.1`, `7.2`, `7.3`, `7.4`    | Specify the PHP version you require  |

For example, if you wish to build an Nginx image running PHP 7.3 you would use:
`docker build -t nhsleadershipacademy/nhsl-ubuntu-php:nginx-7.3 --build-arg --build-arg PHPV=7.3 -f Dockerfile .`

It is likely this will only work for currently supported versions of PHP as unsupported ones are removed from the repository used in this image.

The image is based on Ubuntu 18.04 Bionic, which is an LTS (Long Term Support) release. This means it has full support from Canonical until April 2023.

## Using this image

This image has been heavily customised to fit the needs of the NHS Leadership Academy. We have large amounts of sites running [Moodle](https://moodle.org/) and [WordPress](https://wordpress.org/) and as such there is specific configuration included in this image for these CMSs. This is not to say it cannot be used for other software, it is simply included to make our lives easier.

When running the image, you will need to specify some environment variables for the image it self.

| Variable     | Value        | Comment      |
| ------------ | ------------ | ------------ |
| HEADER_NOSNIFF | `true`/`false` | **Default:** TRUE <br /> Enables or disables strict mime type checking in the browser |
| OSSAPP | `MOODLE`/`WORDPRESS`/`OTHER` | **Default:** OTHER <br /> if set then will include customisations for running Moodle or WordPress (e.g. PHP config in Nginx) |
| CONTAINERROLE | `web`/`worker` | **Default:** WEB <br /> Sets up the container for either serving content or running cron jobs (worker). |
| PHP\_MEMORY\_MAX | Any integer ending M, e.g. `128M` | **Default:** 128M <br /> Sets the PHP Max Memory in Mb for executing scripts. |
| DISABLE_OPCACHE | `true`/`false` | **Default:** TRUE <br /> Enables or disables the PHP opcache. |
| PHP\_OPCACHE\_MEMORY | An integer | **Default:** 16 <br /> Set the amount of Mb to use for opcache memory storage. |
| PHP\_SESSION\_STORE | `REDIS` | If set to `REDIS` PHP will store session files there rather than on the local disk. |
| ATATUS\_APM\_LICENSE_KEY | A string containing the license key | If a license key is set, then Atatus will be enabled. |
| NGINX\_WEB\_ROOT | A path to the web root, e.g. `/src/wordpress` | Set the Nginx public web root. |
| NGINX_PORT | An integer | **Default:** 80 <br /> If set, changes the Nginx port. |
| OLD_DOMAINS | Comma delimited string | If set, will setup Nginx to redirect these domains to the $DOMAIN set by Bamboo. |

### Things to note when moving from previous images
1. You may need to remove the `command: ["/start-worker.sh"]` line from your deployment.k8s file
2. You will need to add a new environment variable to your worker container in deployment.k8s:

    ```
    - name: CONTAINERROLE
      value: worker
    ```
3. Nginx and PHP both run as the `nobody` user under the `nogroup` group. This may not need any changes but if you find you have permissions issues, change the group from `nobody` to `nogroup` in any `chown` statements you run.
4. Your cron should output to /var/log/cronlog and specify a user to run as that isn't root, for example:

    */etc/cron.d/moodle:*
    ```
    * * * * * nobody /src/vendor/public/public/moodle/admin/cli/cron.php > /var/log/cronlog
    ```



### Nginx config overwriting
Modifying Nginx configuration is highly discouraged but sometimes not avoidable. If you really must overwrite the Nginx configuration then please copy it into `/startup-nginx.conf` inside the container. A script runs during container boot that will look for this file and overwrite Nginx's default configuration if needed.

Please note that doing this will stop `OSSAPP` and any `NGINX_` or `HEADER_` options above from working.

### Boot scripting
You may add scripts that run as the container boots, but before Nginx and PHP start by copying files into:

`/startup-all.sh` - scripts that run on both web and worker containers

`/startup-web.sh` - scripts that only run on a 'web' container

`/startup-worker.sh` - scripts that only run on 'worker' containers, generally used for cron jobs
