PHP_VERSION=7.3.14

apt-get update && apt-get install -y --no-install-recommends curl ca-certificates apt-utils   && update-ca-certificates \

apt-get install -y --no-install-recommends     tini     aspell     bash     runit     procps     net-tools     iputils-ping     binutils     bzip2     ca-certificates     curl     enchant     file     argon2     libargon2-0     fontconfig-config     fonts-dejavu-core     hunspell-en-us     icu-devtools     imagemagick     intltool-debian     libapr1     libaprutil1     libbsd0     libc-client2007e     libcurl4     libedit2     libenchant1c2a     libfontconfig1     libfreetype6     libgd3     libglib2.0-0     libglib2.0-data     libgmp10     libgpm2     libgsasl7     libhiredis0.14     libhunspell-1.7-0     libidn2-0     libjbig0     libjpeg62-turbo     libltdl7     libldb1     libtdb1     libtalloc2     libtevent0     libmagic1     libmagic-mgc     libmcrypt4     libncurses5     libnghttp2-14     libntlm0     libpci3     libpcre16-3     libpcre2-16-0     libpcre2-32-0     libpcre2-8-0     libpcre2-posix0     libpcre3     libpcre32-3     libpng16-16     libpq5     libpsl5     libreadline7     librecode0     librtmp1     libsasl2-2     libsasl2-modules     libsensors5     libsnmp30     libsnmp-base     libsodium23     libsqlite3-0     libssh2-1     libssl1.1     libtidy5deb1     libtiff5     libunistring2     libwebp6     libwrap0     libx11-6     libx11-data     libxau6     libxcb1     libxdmcp6     libxml2     libxml2-utils     libxpm4     libxslt1.1     libzip4     mime-support     msmtp     openssl     psmisc     publicsuffix     shared-mime-info     snmp     tar     tcpd     ucf     xz-utils     zlib1g     libpng-tools     libodbc1     webp     libmemcached11     inotify-tools     libonig5

apt-get install -y --no-install-recommends     $PHPIZE_DEPS     build-essential     libaprutil1-dev     libargon2-0-dev     libaspell-dev     libapr1-dev     libc-client2007e-dev     libedit-dev     libenchant-dev     libfreetype6-dev     libgcc-8-dev     libgmp-dev     libhiredis-dev     libicu-dev     libldap2-dev     libltdl-dev     libmcrypt-dev     libnghttp2-dev     libpcre3-dev     libpcre2-dev     libpng++-dev     libpng-dev     libpq-dev     libreadline-dev     librecode-dev     libsasl2-dev     libsodium-dev     libsqlite3-dev     libssl-dev     libstdc++-8-dev     libtidy-dev     libxft-dev     libzip-dev     libldb-dev     zlib1g-dev     libcurl4-openssl-dev     libxml2-dev     libbison-dev     libbz2-dev     libwebp-dev     libjpeg-dev     libxpm-dev     libxslt1-dev     libmemcached-dev     libonig-dev

PHP_INI_DIR=${PHP_PREFIX}/etc/php
PATH=${HTTPD_PREFIX}/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:${PHP_PREFIX}/bin:${PHP_PREFIX}/sbin
mkdir -p ${PHP_PREFIX}/bin/ \
mkdir -p ${PHP_PREFIX}/bin/   && curl -fSL --connect-timeout 30 https://raw.githubusercontent.com/docker-library/php/master/docker-php-source        -o ${PHP_PREFIX}/bin/docker-php-source   && curl -fSL --connect-timeout 30 https://raw.githubusercontent.com/docker-library/php/master/docker-php-ext-install   -o ${PHP_PREFIX}/bin/docker-php-ext-install   && curl -fSL --connect-timeout 30 https://raw.githubusercontent.com/docker-library/php/master/docker-php-ext-enable    -o ${PHP_PREFIX}/bin/docker-php-ext-enable   && curl -fSL --connect-timeout 30 https://raw.githubusercontent.com/docker-library/php/master/docker-php-ext-configure -o ${PHP_PREFIX}/bin/docker-php-ext-configure   && chmod ugo+x ${PHP_PREFIX}/bin/docker-php-*

cd /usr/include
ln -s x86_64-linux-gnu/curl
ln -s /usr/bin/pkg-config /usr/bin/freetype-config

export CFLAGS="-fstack-protector-strong -fpic -fpie -O2" \
export CPPFLAGS="${CFLAGS}" \
export LDFLAGS="-Wl,-O1 -Wl,--hash-style=both -pie" \
export MAKEFLAGS="-j $(expr $(getconf _NPROCESSORS_ONLN) \+ 1)" \

mkdir -p /usr/src/
curl -fSL --connect-timeout 30 https://secure.php.net/get/php-${PHP_VERSION}.tar.xz/from/this/mirror -o /usr/src/php.tar.xz
docker-php-source extract
cd /usr/src/php

