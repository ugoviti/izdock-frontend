## Single Dockerfile for every variant: the per-variant overrides (PHP version, Debian
## release, base image, a few module settings) live in docker-bake.hcl, versions in versions.hcl.
## https://www.php.net/downloads
## https://hub.docker.com/_/php
## PHP 7.4 is EOL: its base image is built from php74/ (official backport for CVE-2026-109618/109619)
ARG APP_VER=8.5.12
ARG DEBIAN_RELEASE=trixie
ARG IMAGE_FROM=php:${APP_VER}-fpm-${DEBIAN_RELEASE}

FROM ${IMAGE_FROM}

LABEL maintainer="Ugo Viti <u.viti@wearequantico.it>"

## app name
ENV APP_NAME="frontend"
ENV APP_DESCRIPTION="PHP-FPM + Apache / NGINX Web Server"

# full app version
ARG APP_VER
ENV APP_VER=${APP_VER}

## app ports
ENV APP_PORT_HTTP=80
ENV APP_PORT_HTTPS=443

## app users
ENV APP_UID=33
ENV APP_GID=33
ENV APP_USR="www-data"
ENV APP_GRP="www-data"

# development debug mode (keep apt cache and source files)
ARG APP_DEBUG=0
ENV APP_DEBUG=$APP_DEBUG

## default variables
ENV DEBIAN_FRONTEND=noninteractive

ENV PREFIX=/usr/local
ENV HTTPD_PREFIX=/etc/apache2
ENV PHP_PREFIX=${PREFIX}
ENV PHP_INI_DIR=${PHP_PREFIX}/etc/php


## php custom modules (pecl): defaults here, overridden per variant by docker-bake.hcl

# https://github.com/Whissi/realpath_turbo/tags
#ENV PHP_MODULE_REALPATH_TURBO_VER '2.0.0'

# https://pecl.php.net/package/xdebug
ARG PHP_MODULE_XDEBUG_VER=3.5.3
ENV PHP_MODULE_XDEBUG_VER=${PHP_MODULE_XDEBUG_VER}

# https://pecl.php.net/package/redis
ARG PHP_MODULE_REDIS_VER=6.3.0
ENV PHP_MODULE_REDIS_VER=${PHP_MODULE_REDIS_VER}

# https://pecl.php.net/package/memcached
ARG PHP_MODULE_MEMCACHED_VER=3.4.0
ENV PHP_MODULE_MEMCACHED_VER=${PHP_MODULE_MEMCACHED_VER}

# pecl modules not built in this variant (no release supporting its PHP version yet)
ARG PHP_PECL_SKIP=""
ENV PHP_PECL_SKIP=${PHP_PECL_SKIP}

## bundled php modules to compile
## modules already built into the base image (e.g. opcache on PHP >= 8.5) are skipped automatically

ENV PHP_MODULES_EXTRA=' \
    bz2 \
    bcmath \
    exif \
    gd \
    mysqli \
    opcache \
    pcntl \
    soap \
    sockets \
    sysvmsg \
    sysvsem \
    sysvshm \
    zip \
    xsl \
    gmp \
    pdo_mysql \
    pdo_pgsql \
    pdo_sqlite \
    pdo_odbc \
    '

## modules to leave out on a given variant (e.g. "pdo_odbc" on PHP 7.4)
ARG PHP_MODULES_EXCLUDE=""

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
#ENV PHP_MODULES_ENABLED
#ENV PHP_MODULES_DISABLED

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
    media-types \
    mailcap \
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
    libapache2-mod-evasive \
    gnupg \
    openssh-client \
    sshpass \
    apt-transport-https \
    '
## NOTE: do not add the "ssh" metapackage: it pulls in openssh-server, which the Debian
## package enables under runit (/etc/runit/runsvdir/default/ssh) and, with network_mode: host,
## binds port 22 of the host. Only the client (openssh-client) is needed.

RUN set -xe && \
  # upgrade the system
  apt-get update && \
  apt-get upgrade -y && \
  apt-get install -y --no-install-recommends ${APP_INSTALL_DEPS} && \
  : "---------- Microsoft ODBC driver repository (matches the image Debian release) ----------" && \
  . /etc/os-release && \
  # microsoft.asc signs the Debian <= 12 repos, microsoft-2025.asc signs the Debian 13 repo
  { curl -fsSL https://packages.microsoft.com/keys/microsoft.asc; curl -fsSL https://packages.microsoft.com/keys/microsoft-2025.asc; } | gpg --dearmor -o /usr/share/keyrings/microsoft-prod.gpg && \
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/microsoft-prod.gpg] https://packages.microsoft.com/debian/${VERSION_ID}/prod ${VERSION_CODENAME} main" > /etc/apt/sources.list.d/mssql-release.list && \
  apt-get update && ACCEPT_EULA=Y apt-get install -y --no-install-recommends \
  msodbcsql18 \
  mssql-tools18 \
  && \
  echo 'export PATH="$PATH:/opt/mssql-tools18/bin"' >> /etc/profile && \
  ln -s /opt/mssql-tools18/bin/* /usr/local/bin/ && \
  # by default disable these modules:
  a2dismod security2 evasive && \
  \
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
    libpq-dev \
    libsqlite3-dev \
    unixodbc-dev \
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
#   : "--- install custom php module: realpath_turbo ---" && \
#   cd /usr/src && \
#   mkdir -p realpath_turbo && \
#   curl -fSL --connect-timeout 15 https://github.com/Whissi/realpath_turbo/releases/download/v${PHP_MODULE_REALPATH_TURBO_VER}/realpath_turbo-${PHP_MODULE_REALPATH_TURBO_VER}.tar.bz2 | tar jx --strip 1 -C realpath_turbo  && \
#   cd realpath_turbo && \
#   phpize && \
#   ./configure --prefix=/usr/local && \
#   make && \
#   #make test NO_INTERACTION=1 && \
#   make install && \
  \
  # PECL sources are built with phpize instead of "pecl install": the official images
  # no longer ship PEAR/PECL since PHP 8.6
  pecl_build() { \
    case " ${PHP_PECL_SKIP} " in *" $1 "*) echo "skip pecl $1: listed in PHP_PECL_SKIP"; return 0 ;; esac; \
    : "--- install custom php module: $1-$2 ---" && \
    mkdir -p /usr/src/pecl/$1 && \
    curl -fsSL --retry 3 --connect-timeout 15 "https://pecl.php.net/get/$1-$2.tgz" | tar xz -C /usr/src/pecl/$1 && \
    cd /usr/src/pecl/$1/$1-$2 && \
    phpize && \
    ./configure && \
    make -j$(nproc) && \
    make install && \
    cd / && rm -rf /usr/src/pecl/$1 ; \
  } && \
  pecl_build redis ${PHP_MODULE_REDIS_VER} && \
  pecl_build memcached ${PHP_MODULE_MEMCACHED_VER} && \
  pecl_build xdebug ${PHP_MODULE_XDEBUG_VER} && \
  \
  : "---------- install extra php modules ----------" && \
  loaded="$(php -m | tr 'A-Z' 'a-z' | sed 's/^zend opcache$/opcache/')" && \
  modules="" && \
  for m in ${PHP_MODULES_EXTRA}; do \
    case " ${PHP_MODULES_EXCLUDE} " in *" $m "*) echo "skip $m: excluded"; continue ;; esac; \
    if echo "$loaded" | grep -qx "$m"; then echo "skip $m: already built in"; continue; fi; \
    modules="$modules $m"; \
  done && \
  case " $modules " in *" gd "*) docker-php-ext-configure gd --with-freetype --with-jpeg ;; esac && \
  case " $modules " in *" pdo_odbc "*) \
    find /usr/lib -name '*.la' -delete && \
    docker-php-ext-configure pdo_odbc --with-pdo-odbc=unixODBC ;; \
  esac && \
  : "--- install modules: $modules ---" && \
  docker-php-ext-install -j$(nproc) $modules && \
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
  # keep the runtime libraries of the compiled extensions (paths made relative so it also works on usrmerged Debian, same as docker-library)
  ldd "$(php -r 'echo ini_get("extension_dir");')"/*.so \
    | awk '/=>/ { so = $(NF-1); if (index(so, "/usr/local/") == 1) { next }; gsub("^/(usr/)?", "", so); printf "*%s\n", so }' \
    | sort -u \
    | xargs -r dpkg-query --search \
    | cut -d: -f1 \
    | sort -u \
    | xargs -rt apt-mark manual \
  && \
  : "---------- removing apt cache and unneeded packages ----------" && \
  apt-get purge --auto-remove -o APT::AutoRemove::RecommendsImportant=false -y && \
  rm -rf /var/lib/apt/lists/* /tmp/* && \
  # update pecl channel definitions https://github.com/docker-library/php/issues/443
  if command -v pecl >/dev/null; then pecl update-channels ;fi && \
  rm -rf /tmp/pear ~/.pearrc /usr/src/pecl \
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
  if [ -e ${PHP_PREFIX}/etc/pear.conf ]; then ln -s ${PHP_PREFIX}/etc/pear.conf /etc/php/pear.conf ;fi && \
  ln -s /usr/lib/apache2/modules /etc/apache2/modules && \
  ln -s /usr/bin/rotatelogs /usr/sbin/rotatelogs && \
  if [ -e "${HTTPD_PREFIX}" ]; then mkdir -p "${HTTPD_PREFIX}/conf.d" ;fi && \
  if [ -e "${HTTPD_PREFIX}" ]; then echo "IncludeOptional ${HTTPD_PREFIX}/conf.d/*.conf" >> "${HTTPD_PREFIX}/apache2.conf" ;fi

# exposed ports
EXPOSE \
  ${APP_PORT_HTTP}/tcp \
  ${APP_PORT_HTTPS}/tcp

# add files to container
COPY Dockerfile /
COPY README.md /
COPY filesystem/ /

# container pre-entrypoint variables
ENV APP_RUNAS=""
ENV MULTISERVICE=""
ENV ENTRYPOINT_TINI=""
ENV WEBSERVER="apache"
ENV WEBSERVER_ENABLED="true"
ENV PHP_ENABLED="true"
ENV PHPFPM_ENABLED="${PHP_ENABLED}"
ENV HTTPD_CONF_FILE="${HTTPD_PREFIX}/apache2.conf"
ENV HTTPD_VIRTUAL_FILE="${HTTPD_PREFIX}/sites-available/000-default.conf"
ENV UMASK=0002

## CI args
ARG APP_VER_BUILD
ARG APP_BUILD_COMMIT
ARG APP_BUILD_DATE

# define other build variables
ENV APP_VER="${APP_VER}"
ENV APP_VER_BUILD="${APP_VER_BUILD}"
ENV APP_BUILD_COMMIT="${APP_BUILD_COMMIT}"
ENV APP_BUILD_DATE="${APP_BUILD_DATE}"

# start the container process
ENTRYPOINT ["/entrypoint.sh"]
CMD ["php-fpm"]
