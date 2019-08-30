# nhsl-ubuntu-php

A Docker for NHS Leadership Academy based on Ubuntu with Nginx mainline and PHP.

Want to build this? Well here you go!
`docker build -t <repository>/<image>:<tag> -f Dockerfile . --no-cache --build-arg PHPV=<version>`

Specify your PHP version above, e.g. 7.3

It is likely this will only work for supported versions of PHP as unsupported ones are removed from the repository used in this image.

The image is based on Ubuntu 18.04 Bionic, which has Long Term Support until April 2028.