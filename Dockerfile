## https://www.php.net/downloads
ARG APP_VER=8.2.20
ARG IMAGE_FROM=php:${APP_VER}-fpm-bullseye

FROM ${IMAGE_FROM}

MAINTAINER Ugo Viti <ugo.viti@initzero.it>

## app name
ENV APP_NAME        "frontend"
ENV APP_DESCRIPTION "PHP-FPM + Apache / NGINX Web Server"

# full app version
ARG APP_VER
ENV APP_VER=${APP_VER}

## app ports
ENV APP_PORT_HTTP   80
ENV APP_PORT_HTTPS  443

## app users
ENV APP_UID         33
ENV APP_GID         33
ENV APP_USR         "www-data"
ENV APP_GRP         "www-data"

# development debug mode (keep apt cache and source files)
ARG APP_DEBUG=0
ENV APP_DEBUG=$APP_DEBUG

## default variables
ENV DEBIAN_FRONTEND=noninteractive

ENV PREFIX=/usr/local
ENV HTTPD_PREFIX=/etc/apache2
ENV PHP_PREFIX=${PREFIX}
ENV PHP_INI_DIR=${PHP_PREFIX}/etc/php


## php custom modules

# https://github.com/Whissi/realpath_turbo/tags
ENV PHP_MODULE_REALPATH_TURBO_VER='2.0.0'

# https://github.com/xdebug/xdebug/tags
ENV PHP_MODULE_XDEBUG_VER='3.3.2'

# https://github.com/phpredis/phpredis/tags
ENV PHP_MODULE_REDIS_VER='6.0.2'

# https://github.com/php-memcached-dev/php-memcached/tags
ENV PHP_MODULE_MEMCACHED_VER='3.2.0'


ENV PHP_MODULES_EXTRA=' \
    bz2 \
    bcmath \
    exif \
    gd \
    mysqli \
    opcache \
    pdo_mysql \
    pcntl \
    soap \
    sockets \
    sysvmsg \
    sysvsem \
    sysvshm \
    zip \
    xsl \
    gmp \
    '


## disabled modules
# calendar
# dba
# enchant
# intl
# pdo_pgsql
# shmop
# tidy
# xmlrpc
# xsl

# php modules enabled/disabled by default
ENV PHP_MODULES_ENABLED=
ENV PHP_MODULES_DISABLED=

# apache vars
ENV DOCUMENTROOT=/var/www/html

## install packages
ENV APP_INSTALL_DEPS=' \
    tini \
    runit \
    rsync \
    net-tools \
    iftop \
    lsof \
    strace \
    tcpdump \
    iputils-ping \
    binutils \
    bzip2 \
    ca-certificates \
    curl \
    file \
    mime-support \
    msmtp \
    psmisc \
    publicsuffix \
    shared-mime-info \
    xz-utils \
    inotify-tools \
    git \
    apache2 \
    nginx \
    libgmpxx4ldbl \
    libapache2-mod-security2 \
    '

RUN set -xe && \
  # upgrade the system
  apt-get update && \
  apt-get upgrade -y && \
  apt-get install -y --no-install-recommends \
  ${APP_INSTALL_DEPS} \
  && \
  #if [ "${WEBSERVER}" = "apache" ]; then apt-get install -y --no-install-recommends apache2 ;fi && \
  #if [ "${WEBSERVER}" = "nginx" ]; then apt-get install -y --no-install-recommends nginx ;fi && \
  \
  # add user www-data to tomcat group, used with initzero backend integration
  groupadd -g 91 tomcat && gpasswd -a www-data tomcat && \
  # cleanup system
  if [ ${APP_DEBUG} -eq 0 ]; then \
  : "---------- removing apt cache ----------" && \
  apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false && \
  rm -rf /var/lib/apt/lists/* \
  ;fi

  
ENV APP_BUILD_DEPS=' \
    libmemcached-dev \
    zlib1g-dev \
    libbz2-dev \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    libicu-dev \
    libxml2-dev \
    libtidy-dev \
    libzip-dev \
    libxslt-dev \
    libgmp-dev \
    '

# install php modules
RUN set -xe && \
: "---------- install build packages ----------" && \
  savedAptMark="$(apt-mark showmanual)" && \
  apt-get update && \
  apt-get install -y --no-install-recommends \
   ${APP_BUILD_DEPS} \
  && \
  : "---------- install custom php modules ----------" && \
  : "--- install custom php module: realpath_turbo ---" && \
  cd /usr/src && \
  mkdir -p realpath_turbo && \
  curl -fSL --connect-timeout 15 https://github.com/Whissi/realpath_turbo/releases/download/v${PHP_MODULE_REALPATH_TURBO_VER}/realpath_turbo-${PHP_MODULE_REALPATH_TURBO_VER}.tar.bz2 | tar jx --strip 1 -C realpath_turbo  && \
  cd realpath_turbo && \
  phpize && \
  ./configure --prefix=/usr/local && \
  make && \
  #make test NO_INTERACTION=1 && \
  make install && \
  \
  : "--- install custom php module: redis ---" && \
  pecl install redis-${PHP_MODULE_REDIS_VER} && \
  \
  : "--- install custom php module: memcached ---" && \
  pecl install memcached-${PHP_MODULE_MEMCACHED_VER} && \
  \
  : "--- install custom php module: xdebug ---" && \
  if [ $APP_VER \> 8.0.0 ]; then \
    pecl install xdebug-${PHP_MODULE_XDEBUG_VER} ; \
  else \
    # stuck to 3.1.6 if php 7
    pecl install xdebug-3.1.6 \
  ;fi && \
  \
  : "---------- install extra php modules ----------" && \
  : "--- install module: gd ---" && \
  if [ $APP_VER \< 7.4.0 ]; then docker-php-ext-configure gd --with-jpeg-dir ;fi && \
  if [ $APP_VER \> 7.4.0 ]; then docker-php-ext-configure gd --with-freetype --with-jpeg ;fi && \
  \
  : "--- install modules: ${PHP_MODULES_EXTRA} ---" && \
  docker-php-ext-install -j$(nproc) ${PHP_MODULES_EXTRA} && \
  \
  : "--- enable modules: ${PHP_MODULES_ENABLED} ---" && \
  if [ ! -z "${PHP_MODULES_ENABLED}" ]; then docker-php-ext-enable ${PHP_MODULES_ENABLED} ;fi && \
  \
  if [ ${APP_DEBUG} -eq 0 ]; then \
  : "---------- cleanup build packages and temp files ----------" && \
  # delete source packages
  docker-php-source delete && \
  \
  # remove packages used for build stage
  apt-mark auto '.*' > /dev/null && \
  if [ ! -z "$savedAptMark" ]; then apt-mark manual $savedAptMark ;fi && \
  ldd "$(php -r 'echo ini_get("extension_dir");')"/*.so \
    | awk '/=>/ { print $3 }' \
    | sort -u \
    | xargs -r dpkg-query -S \
    | cut -d: -f1 \
    | sort -u \
    | xargs -rt apt-mark manual \
  && \
  : "---------- removing apt cache and unneeded packages ----------" && \
  apt-get purge --auto-remove -o APT::AutoRemove::RecommendsImportant=false -y && \
  rm -rf /var/lib/apt/lists/* /tmp/* && \
  # update pecl channel definitions https://github.com/docker-library/php/issues/443
  pecl update-channels && \
  rm -rf /tmp/pear ~/.pearrc \
  ;fi && \
  \
  : "---------- show shipped PHP version ----------" && \
  php --version

# finalize configurations
RUN set -ex && \
  : "---------- finalyzing configurations ----------" && \
  cp -a ${PHP_PREFIX}/etc/php/php.ini-production ${PHP_PREFIX}/etc/php/php.ini && \
  ln -s ${PHP_PREFIX}/etc/php /etc/php && \
  ln -s ${PHP_PREFIX}/etc/php-fpm.d /etc/php/php-fpm.d && \
  ln -s ${PHP_PREFIX}/etc/php-fpm.conf /etc/php/php-fpm.conf && \
  ln -s ${PHP_PREFIX}/etc/pear.conf /etc/php/pear.conf && \
  ln -s /usr/lib/apache2/modules /etc/apache2/modules && \
  ln -s /usr/bin/rotatelogs /usr/sbin/rotatelogs && \
  if [ -e "${HTTPD_PREFIX}" ]; then mkdir -p "${HTTPD_PREFIX}/conf.d" ;fi && \
  if [ -e "${HTTPD_PREFIX}" ]; then echo "IncludeOptional ${HTTPD_PREFIX}/conf.d/*.conf" >> "${HTTPD_PREFIX}/apache2.conf" ;fi

# exposed ports
EXPOSE \
  ${APP_PORT_HTTP}/tcp \
  ${APP_PORT_HTTPS}/tcp

# add files to container
ADD Dockerfile filesystem README.md /

# container pre-entrypoint variables
ENV APP_RUNAS          ""
ENV MULTISERVICE       ""
ENV ENTRYPOINT_TINI    ""
ENV WEBSERVER          "apache"
ENV WEBSERVER_ENABLED  "true"
ENV PHP_ENABLED        "true"
ENV PHPFPM_ENABLED     "${PHP_ENABLED}"
ENV HTTPD_CONF_FILE    "${HTTPD_PREFIX}/apache2.conf"
ENV HTTPD_VIRTUAL_FILE "${HTTPD_PREFIX}/sites-available/000-default.conf"
ENV UMASK              0002

## CI args
ARG APP_VER_BUILD
ARG APP_BUILD_COMMIT
ARG APP_BUILD_DATE

# define other build variables
ENV APP_VER          "${APP_VER}"
ENV APP_VER_BUILD    "${APP_VER_BUILD}"
ENV APP_BUILD_COMMIT "${APP_BUILD_COMMIT}"
ENV APP_BUILD_DATE   "${APP_BUILD_DATE}"

# start the container process
ENTRYPOINT ["/entrypoint.sh"]
CMD ["php-fpm"]
