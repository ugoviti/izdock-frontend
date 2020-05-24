ARG IMAGE_FROM=debian:buster-slim
ARG IMAGE_FROM_HTTPD=httpd:2.4.43
#ARG IMAGE_FROM_PHP=php:7.4
#ARG IMAGE_FROM_V8=alexmasterov/alpine-libv8:6.7

FROM ${IMAGE_FROM_HTTPD} as httpd
#FROM ${IMAGE_FROM_PHP} as php
#FROM ${IMAGE_FROM_V8} as libv8
FROM ${IMAGE_FROM}

MAINTAINER Ugo Viti <ugo.viti@initzero.it>
ENV APP_NAME        "httpd"
ENV APP_DESCRIPTION "Apache HTTP Server"

### apps versions
## https://www.php.net/downloads (php-*.tar.xz format)
ARG PHP_VERSION=7.4.6
ARG PHP_SHA256=d740322f84f63019622b9f369d64ea5ab676547d2bdcf12be77a5a4cffd06832

## https://httpd.apache.org/download.cgi
#ARG HTTPD_VERSION=2.4.41

## php modules version to compile
# https://github.com/phpredis/phpredis/releases
ARG REDIS_VERSION=5.2.2

# https://github.com/php-memcached-dev/php-memcached/releases
ARG MEMCACHED_VERSION=3.1.5

# https://github.com/xdebug/xdebug/releases
ARG XDEBUG_VERSION=2.9.5

# https://github.com/Whissi/realpath_turbo/releases
#ARG REALPATHTURBO_VERSION=2.0.0

# https://github.com/msgpack/msgpack-php/releases
#ARG MSGPACK_VERSION=2.0.3

# https://github.com/tarantool/tarantool-php/releases
#ARG TARANTOOL_VERSION=0.3.2

# https://github.com/mongodb/mongo-php-driver/releases
#ARG MONGODB_VERSION=1.6.1

# https://github.com/phpv8/php-v8/releases
#ARG PHPV8_VERSION=0.2.2

## default variables
ENV DEBIAN_FRONTEND=noninteractive

ENV PREFIX=/usr/local
ENV HTTPD_PREFIX=${PREFIX}/apache2
ENV PHP_PREFIX=${PREFIX}/php
ENV PHP_INI_DIR=${PHP_PREFIX}/etc/php
ENV PATH=${HTTPD_PREFIX}/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:${PHP_PREFIX}/bin:${PHP_PREFIX}/sbin

# PHP extra modules to enable
ENV PHP_MODULES_PECL="igbinary apcu"
ENV PHP_MODULES_EXTRA="msgpack opcache memcached redis xdebug phpiredis realpath_turbo tarantool"
#disabled: mongodb v8

#ENV PHP_MODULES_ENABLED="all"
ENV PHP_MODULES_ENABLED="redis"
# NB. do not use PHP_MODULES as variable name otherwise the build phase will fail

# Apache vars
ENV DOCUMENTROOT=/var/www/localhost/htdocs

# install gcsfuse
#COPY --from=gcsfuse /go/bin/gcsfuse ${PREFIX}/bin/

# prevent Debian's PHP packages from being installed
# https://github.com/docker-library/php/pull/542
RUN set -ex; \
  { \
  echo 'Package: php*'; \
  echo 'Pin: release *'; \
  echo 'Pin-Priority: -1'; \
  } > /etc/apt/preferences.d/no-debian-php

## install apache/php needed libraries and persistent / runtime deps
RUN set -ex \
  # install curl and update ca certificates
  && apt-get update && apt-get install -y --no-install-recommends curl ca-certificates apt-utils \
  && update-ca-certificates \
  # upgrade the system
  && apt-get update && apt-get upgrade -y \
  # instal all needed packages
  && apt-get install -y --no-install-recommends \
    tini \
    aspell \
    bash \
    runit \
    procps \
    net-tools \
    iputils-ping \
    binutils \
    bzip2 \
    ca-certificates \
    curl \
    enchant \
    file \
    argon2 \
    libargon2-0 \
    fontconfig-config \
    fonts-dejavu-core \
    hunspell-en-us \
    icu-devtools \
    imagemagick \
    intltool-debian \
    libapr1 \
    libaprutil1 \
    libbsd0 \
    libc-client2007e \
    libcurl4 \
    libedit2 \
    libenchant1c2a \
    libfontconfig1 \
    libfreetype6 \
    libgd3 \
    libglib2.0-0 \
    libglib2.0-data \
    libgmp10 \
    libgpm2 \
    libgsasl7 \
    libhiredis0.14 \
    libhunspell-1.7-0 \
    libidn2-0 \
    libjbig0 \
    libjpeg62-turbo \
    libltdl7 \
    libldb1 \
    libtdb1 \
    libtalloc2 \
    libtevent0 \
    libmagic1 \
    libmagic-mgc \
    libmcrypt4 \
    libncurses5 \
    libnghttp2-14 \
    libntlm0 \
    libpci3 \
    libpcre16-3 \
    libpcre2-16-0 \
    libpcre2-32-0 \
    libpcre2-8-0 \
    libpcre2-posix0 \
    libpcre3 \
    libpcre32-3 \
    libpng16-16 \
    libpq5 \
    libpsl5 \
    libreadline7 \
    librecode0 \
    librtmp1 \
    libsasl2-2 \
    libsasl2-modules \
    libsensors5 \
    libsnmp30 \
    libsnmp-base \
    libsodium23 \
    libsqlite3-0 \
    libssh2-1 \
    libssl1.1 \
    libtidy5deb1 \
    libtiff5 \
    libunistring2 \
    libwebp6 \
    libwrap0 \
    libx11-6 \
    libx11-data \
    libxau6 \
    libxcb1 \
    libxdmcp6 \
    libxml2 \
    libxml2-utils \
    libxpm4 \
    libxslt1.1 \
    libzip4 \
    mime-support \
    msmtp \
    openssl \
    psmisc \
    publicsuffix \
    shared-mime-info \
    snmp \
    tar \
    tcpd \
    ucf \
    xz-utils \
    zlib1g \
    libpng-tools \
    libodbc1 \
    webp \
    libmemcached11 \
    inotify-tools \
    libonig5 \
    brotli \
    libbrotli1 \
#    dma \
#    libcurl4-gnutls \
#    default-mysql-client-core \
#  && addgroup -g 82 -S www-data \
#  && adduser -u 82 -S -D -h /var/cache/www-data -s /sbin/nologin -G www-data www-data \
  # add user www-data to tomcat group, used with initzero backend integration
  && groupadd -g 91 tomcat && gpasswd -a www-data tomcat \
  # cleanup system
  && : "---------- Removing build dependencies, clean temporary files ----------" \
  && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
  && rm -rf /var/lib/apt/lists/* /tmp/*

## ================ HTTPD ================ ##
# copy some files from the official httpd image
COPY --from=httpd ${HTTPD_PREFIX} ${HTTPD_PREFIX}
#COPY --from=httpd ${PREFIX}/bin/httpd-foreground ${HTTPD_PREFIX}/bin/

## ================ PHP ================ ##
# copy some files from the official php image
#COPY --from=php ${PREFIX}/bin/docker-php-source ${PREFIX}/bin/docker-php-ext-* ${PREFIX}/bin/docker-php-entrypoint ${PHP_PREFIX}/bin/

# copy v8 libs
## thanks to https://hub.docker.com/r/alexmasterov/alpine-php/
#COPY --from=libv8 ${PREFIX}/v8 ${PREFIX}/v8

# dependencies required for running "phpize"
# (see persistent deps below)
ENV PHPIZE_DEPS \
  autoconf \
  dpkg-dev \
  file \
  g++ \
  gcc \
  libc-dev \
  make \
  pkg-config \
  re2c \
  bison

# compile php
RUN set -ex \
  && savedAptMark="$(apt-mark showmanual)" \
  && apt-get update \
  && apt-get install -y --no-install-recommends \
    $PHPIZE_DEPS \
    build-essential \
    libaprutil1-dev \
    libargon2-0-dev \
    libaspell-dev \
    libapr1-dev \
    libc-client2007e-dev \
    libedit-dev \
    libenchant-dev \
    libfreetype6-dev \
    libgcc-8-dev \
    libgmp-dev \
    libhiredis-dev \
    libicu-dev \
    libldap2-dev \
    libltdl-dev \
    libmcrypt-dev \
    libnghttp2-dev \
    libpcre3-dev \
    libpcre2-dev \
    libpng++-dev \
    libpng-dev \
    libpq-dev \
    libreadline-dev \
    librecode-dev \
    libsasl2-dev \
    libsodium-dev \
    libsqlite3-dev \
    libssl-dev \
    libstdc++-8-dev \
    libtidy-dev \
    libxft-dev \
    libzip-dev \
    libldb-dev \
    zlib1g-dev \
    libcurl4-openssl-dev \
    libxml2-dev \
    libbison-dev \
    libbz2-dev \
    libwebp-dev \
    libjpeg-dev \
    libxpm-dev \
    libxslt1-dev \
    libmemcached-dev \
    libonig-dev \
    libbrotli-dev \
#    libcurl4-gnutls-dev \
#    default-libmysqlclient-dev \
    ${PHP_EXTRA_BUILD_DEPS:-} \
  # download official php docker scripts
  && mkdir -p ${PHP_PREFIX}/bin/ \
  && curl -fSL --connect-timeout 30 https://raw.githubusercontent.com/docker-library/php/master/docker-php-source        -o ${PHP_PREFIX}/bin/docker-php-source \
  && curl -fSL --connect-timeout 30 https://raw.githubusercontent.com/docker-library/php/master/docker-php-ext-install   -o ${PHP_PREFIX}/bin/docker-php-ext-install \
  && curl -fSL --connect-timeout 30 https://raw.githubusercontent.com/docker-library/php/master/docker-php-ext-enable    -o ${PHP_PREFIX}/bin/docker-php-ext-enable \
  && curl -fSL --connect-timeout 30 https://raw.githubusercontent.com/docker-library/php/master/docker-php-ext-configure -o ${PHP_PREFIX}/bin/docker-php-ext-configure \
  && chmod ugo+x ${PHP_PREFIX}/bin/docker-php-* \
  #&& : "---------- FIX: iconv - download ----------" \
  #&& apk add --no-cache --virtual .ext-runtime-dependencies --repository http://dl-cdn.alpinelinux.org/alpine/edge/testing/ gnu-libiconv-dev \
  #&& : "---------- FIX: iconv - replace binary and headers ----------" \
  #&& (mv /usr/bin/gnu-iconv /usr/bin/iconv; mv /usr/include/gnu-libiconv/*.h /usr/include; rm -rf /usr/include/gnu-libiconv) \
  #\
  #&& : "---------- FIX: libpcre2 ----------" \
  #&& (cd /usr/lib; ln -sf libpcre2-posix.a libpcre2.a; ln -sf libpcre2-posix.so libpcre2.so) \
  #\
  && : "---------- FIX: configuring default apache mpm worker to mpm_prefork, otherwise php get force compiled as ZTS (ThreadSafe support) if mpm_event or mpm_worker are used ----------" \
  && sed -r "s|^LoadModule mpm_|#LoadModule mpm_|i" -i "${HTTPD_PREFIX}/conf/httpd.conf" \
  && sed -r "s|^#LoadModule mpm_prefork_module|LoadModule mpm_prefork_module|i" -i "${HTTPD_PREFIX}/conf/httpd.conf" \
  && : "---------- FIX: libcurl not working ----------" \
  && cd /usr/include \
  && ln -s x86_64-linux-gnu/curl \
  \
  && : "---------- FIX: freetype-config missing in debian buster ----------" \
  && ln -s /usr/bin/pkg-config /usr/bin/freetype-config \
  \
  && : "---------- PHP Build Flags ----------" \
  && export CFLAGS="-fstack-protector-strong -fpic -fpie -O2" \
  && export CPPFLAGS="${CFLAGS}" \
  && export LDFLAGS="-Wl,-O1 -Wl,--hash-style=both -pie" \
  && export MAKEFLAGS="-j $(expr $(getconf _NPROCESSORS_ONLN) \+ 1)" \
  \
  && : "---------- PHP Download ----------" \
  && mkdir -p /usr/src/ \
  && PHP_SOURCE="https://secure.php.net/get/php-${PHP_VERSION}.tar.xz/from/this/mirror" \
  && curl -fSL --connect-timeout 30 ${PHP_SOURCE} -o /usr/src/php.tar.xz \
  && echo "$PHP_SHA256 /usr/src/php.tar.xz" | sha256sum -c - \
  && : "---------- PHP Build ----------" \
  && docker-php-source extract \
  && mkdir -p ${PHP_INI_DIR}/conf.d \
  \
  && cd /usr/src/php \
  && gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)" \
  && debMultiarch="$(dpkg-architecture --query DEB_BUILD_MULTIARCH)" \
  && ./configure \
    --build="$gnuArch" \
    --prefix=${PHP_PREFIX} \
    --sysconfdir=${PHP_INI_DIR} \
    --with-config-file-path=${PHP_INI_DIR} \
    --with-config-file-scan-dir=${PHP_INI_DIR}/conf.d \
    $([ ! -z "$HTTPD_PREFIX" ] \
      && echo "--with-apxs2=${HTTPD_PREFIX}/bin/apxs" \
     ) \
    --with-libdir="lib/$debMultiarch" \
    $([ $PHP_VERSION \> 7.0.0 ] \
      && echo "--disable-phpdbg-webhelper" \
      && echo "--enable-huge-code-pages" \
      && echo "--with-pcre-jit" \
      && echo "--with-openssl" \
     ) \
    $([[ $PHP_VERSION > 7.0.0 && $PHP_VERSION < 7.4.0 ]] \
      && echo "--enable-opcache-file" \
     ) \
    $([ $PHP_VERSION \< 7.2.0 ] \
      && echo "--disable-gd-native-ttf" \
     ) \
    $([ $PHP_VERSION \> 7.2.0 ] \
      && echo "--with-sodium=shared" \
      && echo "--with-password-argon2" \
     ) \
    $([ $PHP_VERSION \< 7.4.0 ] \
      && echo "--enable-zip" \
      && echo "--with-libxml-dir" \
      && echo "--with-png-dir" \
      && echo "--with-gd" \
      && echo "--with-jpeg-dir" \
      && echo "--with-libzip" \
      && echo "--with-pcre-regex" \
      && echo "--with-webp-dir" \
      && echo "--enable-libxml" \
     ) \
    $([ $PHP_VERSION \> 7.4.0 ] \
      && echo "--enable-gd" \
      && echo "--with-freetype" \
      && echo "--with-jpeg" \
      && echo "--with-xpm" \
      && echo "--with-webp" \
      && echo "--with-zip" \
     ) \
    --disable-cgi \
    --disable-debug \
    --enable-bcmath \
    --enable-calendar \
    --enable-dba \
    --enable-dom \
    --enable-exif \
    --enable-fd-setsize=$(ulimit -n) \
    --enable-fpm \
    --enable-ftp \
    --enable-inline-optimization \
    --enable-intl \
    --enable-json \
    --enable-mbregex \
    --enable-mbstring \
    --enable-mysqlnd \
    --enable-opcache \
    --enable-option-checking=fatal \
    --enable-pcntl \
    --enable-phar \
    --enable-session \
    --enable-shmop \
    --enable-soap \
    --enable-sockets \
    --enable-sysvmsg \
    --enable-sysvsem \
    --enable-sysvshm \
    --enable-xml \
    --enable-xmlreader \
    --enable-xmlwriter \
    --with-bz2 \
    --with-curl \
    --with-enchant \
    --with-fpm-group=www-data \
    --with-fpm-user=www-data \
    --with-iconv \
    --with-libedit \
    --without-imap \
    --with-mhash \
    --with-mysqli \
    --with-pdo-mysql \
    --with-pdo-pgsql \
    --with-pdo-sqlite \
    --with-pear \
    --with-readline \
    --with-system-ciphers \
    --with-xmlrpc \
    --with-xsl \
    --with-zlib \
    --without-pgsql \
    --with-tidy \
#    --disable-dmalloc \
#    --disable-dtrace \
#    --disable-embedded-mysqli \
#    --disable-gcov \
#    --disable-gd-jis-conv \
#    --disable-ipv6 \
#    --disable-libgcc \
#    --disable-maintainer-zts \
#    --disable-phpdbg \
#    --disable-phpdbg-debug \
#    --disable-re2c-cgoto \
#    --disable-rpath \
#    --disable-sigchild \
#    --disable-static \
  && make -j "$(nproc)" \
  && make install \
  && find /usr/local/bin /usr/local/sbin -type f -executable -exec strip --strip-all '{}' + || true \
  \
  # install default php.ini
  && cp -a /usr/src/php/php.ini-production ${PHP_PREFIX}/etc/php/php.ini \
  \
  # php prefix workaround
  && mkdir -p ${PREFIX}/etc \
  && ln -s ${PHP_PREFIX}/etc/php ${PREFIX}/etc/php \
  # compile native php modules
  && if [ $PHP_VERSION \< 7.0.0 ]; then \
    docker-php-ext-install -j"$(getconf _NPROCESSORS_ONLN)" mcrypt \
  ; fi \
  \
  # compile pecl modules
  && for MODULE in ${PHP_MODULES_PECL}; do \
  if [ $PHP_VERSION \< 7 ]; then \
    [ "$MODULE" = memcached ] && MODULE=memcached-2.2.0 ;\
  fi ;\
  # skip these modules if php 7
  if [ $PHP_VERSION \< 7 ]; then \
   case "$MODULE" in \
     apcu|ssh2-1) echo "skipping pecl module: $MODULE" ;;\
   esac ;\
  else \
    echo "installing pecl module: $MODULE" ;\
    yes yes | pecl install $MODULE ;\
  fi ;\
  done \
  \
  # compile external php modules for version >5.6.0
  && if [ $PHP_VERSION \> 5.6.0 ];then cd /usr/src \
  && : "---------- phpredis ----------" \
  && curl -fSL --connect-timeout 30 https://github.com/phpredis/phpredis/archive/${REDIS_VERSION}.tar.gz | tar xz -C /usr/src/ \
  && cd /usr/src/phpredis-${REDIS_VERSION} \
  && phpize \
  && ./configure \
  && make \
  && make install \
  ;fi \
  \
  # compile external php modules for version >7.0.0
  && if [ $PHP_VERSION \> 7.0.0 ];then cd /usr/src \
  && : "---------- memcached ----------" \
  && curl -fSL --connect-timeout 30 "https://github.com/php-memcached-dev/php-memcached/archive/v${MEMCACHED_VERSION}.tar.gz" | tar xz -C /usr/src/ \
  && cd /usr/src/php-memcached-${MEMCACHED_VERSION} \
  && phpize \
  && ./configure \
  && make \
  && make install \
  && : "---------- xdebug ----------" \
  && curl -fSL --connect-timeout 30 "https://github.com/xdebug/xdebug/archive/${XDEBUG_VERSION}.tar.gz" | tar xz -C /usr/src/ \
  && cd /usr/src/xdebug-${XDEBUG_VERSION} \
  && phpize \
  && ./configure \
  && make \
  && make install \
  ;fi \
  \
#   && : "---------- msgpack ----------" \
#   && curl -fSL --connect-timeout 30 "https://github.com/msgpack/msgpack-php/archive/msgpack-${MSGPACK_VERSION}.tar.gz" | tar xz -C /usr/src/ \
#   && cd /usr/src/msgpack-php-msgpack-${MSGPACK_VERSION} \
#   && phpize \
#   && ./configure \
#   && make \
#   && make install \
#   && : "---------- tarantool ----------" \
#   && curl -fSL --connect-timeout 30 "https://github.com/tarantool/tarantool-php/archive/${TARANTOOL_VERSION}.tar.gz" | tar xz -C /usr/src/ \
#   && cd /usr/src/tarantool-php-${TARANTOOL_VERSION} \
#   && phpize \
#   && ./configure \
#   && make \
#   && make install \
#   && : "---------- realpathturbo - https://bugs.php.net/bug.php?id=52312 ----------" \
#   && curl -fSL --connect-timeout 30 "https://github.com/Whissi/realpath_turbo/archive/v${REALPATHTURBO_VERSION}.tar.gz" | tar xz -C /usr/src/ \
#   && cd /usr/src/realpath_turbo-${REALPATHTURBO_VERSION} \
#   && phpize \
#   && ./configure \
#   && make \
#   && make install \
#   && : "---------- MongoDB ----------" \
#   && apk add --virtual .mongodb-build-dependencies cmake pkgconfig \
#   && apk add --virtual .mongodb-runtime-dependencies libressl2.7-libtls \
#   && MONGODB_FILENAME="mongodb-${MONGODB_VERSION}" \
#   && MONGODB_SOURCE="https://github.com/mongodb/mongo-php-driver/releases/download/${MONGODB_VERSION}/${MONGODB_FILENAME}.tgz" \
#   && curl -fSL --connect-timeout 30 ${MONGODB_SOURCE} | tar xz -C /usr/src/ \
#   && cd /usr/src/${MONGODB_FILENAME} \
#   && phpize \
#   && ./configure --with-mongodb-ssl=libressl \
#   && make \
#   && make install \
#   && apk del .mongodb-build-dependencies \
#   && : "---------- php-v8 ----------" \
#   && PHPV8_FILENAME="php-v8-${PHPV8_VERSION}" \
#   && PHPV8_SOURCE="https://github.com/pinepain/php-v8/archive/v${PHPV8_VERSION}.tar.gz" \
#   && curl -fSL --connect-timeout 30 ${PHPV8_SOURCE} | tar xz -C /usr/src/ \
#   && cd /usr/src/${PHPV8_FILENAME} \
#   && phpize \
#   && ./configure --with-v8=${PREFIX}/v8 \
#   && make \
#   && make install \
  # enable all compiled modules
  # disabled: use entrypoint-hook.sh instead
  #&& for MODULE in ${PHP_PREFIX}/lib/php/extensions/*/*.so; do docker-php-ext-enable $MODULE ; done \
  \
  # cleanup system
  && : "---------- Removing build dependencies, clean temporary files ----------" \
  # https://github.com/docker-library/php/issues/443
  && pecl update-channels \
  && rm -rf /tmp/pear ~/.pearrc \
  # remove php sources
  && cd /usr/src/php \
  && make clean \
  && cd \
  && docker-php-source delete \
  # remove packages used for build stage
  && apt-mark auto '.*' > /dev/null \
  && [ -z "$savedAptMark" ] || apt-mark manual $savedAptMark; \
  find /usr/local -type f -executable -exec ldd '{}' ';' \
  | awk '/=>/ { print $(NF-1) }' \
  | sort -u \
  | xargs -r dpkg-query --search \
  | cut -d: -f1 \
  | sort -u \
  | xargs -r apt-mark manual \
  \
  && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/usr/src/* /usr/src/* ${PHP_PREFIX}/lib/php/test ${PHP_PREFIX}/lib/php/doc ${PHP_PREFIX}/php/man \
  \
  && : "---------- Show Builded PHP Version ----------" \
  && php --version

## post build configurations
RUN set -xe \
  && : "---------- Post Build configurations ----------" \
  # system paths and files configuration
  && cd /etc \
  # APACHE: alpine directory structure compatibility
  && mkdir -p "${HTTPD_PREFIX}/conf/conf.d" \
  && mkdir -p /run/apache2 \
  && mkdir -p /var/cache/apache2/proxy \
  && mkdir -p ${DOCUMENTROOT} \
  && ln -s ${HTTPD_PREFIX}/bin/rotatelogs /usr/sbin/rotatelogs \
  && ln -s ${HTTPD_PREFIX}/conf apache2 \
  && chown -R www-data:www-data /run/apache2 \
  && chown -R www-data:www-data /var/cache/apache2 \
  && sed "/Listen 80/a Listen 443 https" -i "${HTTPD_PREFIX}/conf/httpd.conf" \
  && sed "s|${PREFIX}/apache2/htdocs|${DOCUMENTROOT}|" -i "${HTTPD_PREFIX}/conf/httpd.conf" \
  && sed "s/^User.*/User www-data/" -i "${HTTPD_PREFIX}/conf/httpd.conf" \
  && sed "s/^Group.*/Group www-data/" -i "${HTTPD_PREFIX}/conf/httpd.conf" \
  #&& sed "s/#ServerName.*/ServerName ${HOSTNAME}/" -i "${HTTPD_PREFIX}/conf/httpd.conf" \
  && echo "IncludeOptional /etc/apache2/conf.d/*.conf" >> "${HTTPD_PREFIX}/conf/httpd.conf" \
  && sed -ri -e 's!^(\s*CustomLog)\s+\S+!\1 /proc/self/fd/1!g' -e 's!^(\s*ErrorLog)\s+\S+!\1 /proc/self/fd/2!g' "${HTTPD_PREFIX}/conf/httpd.conf" \
  \
  # PHP: for compatibility with alpine linux make config symlinks to system default /etc dir
  && ln -s ${PHP_PREFIX}/etc/php \
  && ln -s ${PHP_PREFIX}/etc/pear.conf

## php-fpm support
RUN set -ex \
  && : "---------- PHP-FPM configuration ----------" \
  && cd ${PHP_PREFIX}/etc/php \
  && if [ -d php-fpm.d ]; then \
    # for some reason, upstream's php-fpm.conf.default has "include=NONE/etc/php/php-fpm.d/*.conf"
    sed 's!=NONE/!=!g' php-fpm.conf.default | tee php-fpm.conf > /dev/null; \
    cp php-fpm.d/www.conf.default php-fpm.d/www.conf; \
  else \
    # PHP 5.x doesn't use "include=" by default, so we'll create our own simple config that mimics PHP 7+ for consistency
    mkdir php-fpm.d; \
    cp php-fpm.conf.default php-fpm.d/www.conf; \
    { \
      echo '[global]'; \
      echo 'include=etc/php/php-fpm.d/*.conf'; \
    } | tee php-fpm.conf; \
    fi \
    && { \
      echo '[global]'; \
      echo 'error_log = /proc/self/fd/2'; \
      echo; \
      echo '[www]'; \
      echo '; if we send this to /proc/self/fd/1, it never appears'; \
      echo 'access.log = /proc/self/fd/2'; \
      echo; \
      echo 'clear_env = no'; \
      echo; \
      echo '; Ensure worker stdout and stderr are sent to the main error log.'; \
      echo 'catch_workers_output = yes'; \
    } | tee php-fpm.d/docker.conf \
    && { \
      echo '[global]'; \
      echo 'daemonize = no'; \
      echo; \
      echo '[www]'; \
      echo 'listen = 9000'; \
    } | tee php-fpm.d/zz-docker.conf

# exposed ports
EXPOSE 80/TCP 443/TCP

# container pre-entrypoint variables
ENV MULTISERVICE    "false"
ENV ENTRYPOINT_TINI "true"
ENV UMASK           0002

# add files to container
ADD Dockerfile filesystem VERSION README.md /

# start the container process
ENTRYPOINT ["/entrypoint.sh"]
CMD ["httpd", "-D", "FOREGROUND"]
