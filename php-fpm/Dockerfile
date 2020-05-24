ARG IMAGE_FROM="izdock/httpd:php7.4"
FROM ${IMAGE_FROM}

MAINTAINER Ugo Viti <ugo.viti@initzero.it>

# custom app configuration variables
ENV APP_NAME              "php-fpm"
ENV APP_DESCRIPTION       "PHP-FPM (FastCGI Process Manager)"
ENV APP_CONF              ""
ENV APP_CONF_PHP          ""
ENV APP_DATA              ""
ENV APP_LOGS              ""

ENV HTTPD_ENABLED false
ENV PHP_ENABLED   true
ENV PHP_PREFIX /usr/local/php

WORKDIR /var/www/html

EXPOSE 9000

# set default umask
ENV UMASK           0002

# container pre-entrypoint variables
ENV MULTISERVICE    "false"
ENV ENTRYPOINT_TINI "true"

# add files to container
ADD Dockerfile VERSION README.md /

# start the container process
ENTRYPOINT ["/entrypoint.sh"]
CMD ["php-fpm"]
