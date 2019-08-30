# nhsl-ubuntu-php

A Docker for NHS Leadership Academy based on Ubuntu with Nginx mainline and PHP.

Want to build this? Well here you go!
`docker build -t <repository>/<image>:<tag> -f Dockerfile . --no-cache --build-arg PHPV=<version>`

Specify your PHP version above, e.g. 7.3

It is likely this will only work for supported versions of PHP as unsupported ones are removed from the repository used in this image.

The image is based on Ubuntu 18.04 Bionic, which has Long Term Support until April 2028.

## Using this image
If you wish to make changes to the image, for example to add your application code, you should include this image at the top of your Dockerfile, doing something like:

```
FROM nhsleadership/nhsl-ubuntu-php:7.3-master

COPY / /src/public/
COPY config/custom-http.conf /etc/nginx/custom-http.conf
```

## Options
There are a few items configurable by copying files into the image.

### Nginx config
You can add snippets into the base Nginx HTTP server config by simply copying a file into `/etc/nginx/custom/snippets.conf` - the file will automatically be included in the Nginx HTTP stanza. Alternatively you could replace the entire Nginx config by overwriting `/etc/nginx/nginx.conf` but this is highly discouraged as it will remove things like Health checks as used by Kubernetes.

### Boot scripting
You may add scripts that run as the container boots, but before Nginx and PHP start by copying files into:

`/startup-all.sh` - scripts that run on both web and worker containers

`/startup-web.sh` - scripts that only run on a 'web' container

`/startup-worker.sh` - scripts that only run on 'worker' containers, generally used for cron jobs

### Run time variables