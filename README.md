# Description
Production ready Apache / NGINX Web Server + PHP-FPM + izsendmail for MTA sending and logging

# Supported tags
* `8.0.X-COMMIT`, `8.0.X-BUILD`, `8.0.X`, `8.0`, `8`, `latest`
* `7.4.X-COMMIT`, `7.4.X-BUILD`, `7.4.X`, `7.4`, `7`
* `7.2.X-COMMIT`, `7.2.X-BUILD`, `7.2.X`, `7.2`

Where **X** is the patch version number, **COMMIT** is the GIT commit ID, and **BUILD** is the build number (look into project [Tags](https://hub.docker.com/r/izdock/izpbx-frontend/tags) page to discover the latest versions) 

# Dockerfile
- https://github.com/ugoviti/izdock-frontend/blob/master/Dockerfile

# Features
- Small image footprint
- Based on official [php](/_/php/) and [Debian Buster-Slim](/_/debian/) image
- OnDemand configurable Web Server via `WEBSERVER` ENV (apache or nginx)
- OnDemand configurable Apache MPM Worker (use **event** or **worker** for best scalability and memory optimization, PHP get automatically disabled because is not ZTS compiled). The default Apache MPM Worker is **event** (if prefork is used, php-fpm will be disabled because it's incompatible)
- Included izsendmail bash script as wrapper for `msmtp` used for smarthost delivery of mail messages sent from PHP scripts using sendmail() function
- Automatically generate Self Signed SSL certificates if not found into configuration to avoid apache startup problems
- Integrated PHP-FPM support via filesystem sockets and using runit service manager (antipattern)
- Many customizable variables to use

# What is php?
PHP is a server-side scripting language designed for web development, but which can also be used as a general-purpose programming language. PHP can be added to straight HTML or it can be used with a variety of templating engines and web frameworks. PHP code is usually processed by an interpreter, which is either implemented as a native module on the web-server or as a common gateway interface (CGI).

> [wikipedia.org/wiki/PHP](https://en.wikipedia.org/wiki/PHP)

![logo](https://raw.githubusercontent.com/docker-library/docs/01c12653951b2fe592c1f93a13b4e289ada0e3a1/php/logo.png)

# What is httpd?
The Apache HTTP Server, colloquially called Apache, is a Web server application notable for playing a key role in the initial growth of the World Wide Web. Originally based on the NCSA HTTPd server, development of Apache began in early 1995 after work on the NCSA code stalled. Apache quickly overtook NCSA HTTPd as the dominant HTTP server, and has remained the most popular HTTP server in use since April 1996.

> [wikipedia.org/wiki/Apache_HTTP_Server](http://en.wikipedia.org/wiki/Apache_HTTP_Server)

![logo](https://www.apache.org/img/asf_logo.png)

# What is nginx?
Nginx (pronounced "engine-x") is an open source reverse proxy server for HTTP, HTTPS, SMTP, POP3, and IMAP protocols, as well as a load balancer, HTTP cache, and a web server (origin server). The nginx project started with a strong focus on high concurrency, high performance and low memory usage. It is licensed under the 2-clause BSD-like license and it runs on Linux, BSD variants, Mac OS X, Solaris, AIX, HP-UX, as well as on other *nix flavors. It also has a proof of concept port for Microsoft Windows.

> [wikipedia.org/wiki/Nginx](https://en.wikipedia.org/wiki/Nginx)

![logo](https://raw.githubusercontent.com/docker-library/docs/01c12653951b2fe592c1f93a13b4e289ada0e3a1/nginx/logo.png)


# How to use this image.

This image a selectable webserver (Apache or NGINX) with and PHP already installed (**PHP-FPM**) with some modules already compiled.

# Environment default variables

You can change the default behaviour using the following variables (in bold the default values):

**Docker customizable Variables:**
```
## webserver options
: ${ENTRYPOINT_TINI:=true}
: ${MULTISERVICE:=true}            # (true|**false**) enable multiple service manager
: ${UMASK:=0002}                   # (**0002**) default umask when creating new files
: ${SERVERNAME:=$HOSTNAME}         # (**$HOSTNAME**) default web server hostname
: ${RUNIT_DIR:=/etc/service}       # RUNIT services dir

: ${WEBSERVER:=apache}             # (*apache**|nginx|none) default webserver (none or empty = disabled)
: ${WEBSERVER_ENABLED:=true}       # (**true**|false) enable web server

: ${PHPFPM_ENABLED:=true}          # (true|**false**) enable php-fpm service

: ${HTTPD_ENABLED:=false}          # (**true**|false) enable apache web server
: ${HTTPD_MOD_SSL:=false}          # (true|**false**) enable apache module mod_ssl
: ${HTTPD_CONF_DIR:=/etc/apache2}  # (**/etc/apache2**) apache config dir
: ${HTTPD_CONF_FILE:=$HTTPD_CONF_DIR/apache2.conf} # apache master config file
: ${HTTPD_VIRTUAL_FILE:=$HTTPD_CONF_DIR/sites-available/000-default.conf} # apache default virtual config file
: ${HTTPD_MPM:=event}              # (event|worker|**prefork**) # default apache mpm worker to use

: ${NGINX_ENABLED:=false}          # (true|**false**) enable nginx web server
: ${NGINX_CONF_DIR:=/etc/nginx}    # (**/etc/nginx**) nginx config dir
: ${NGINX_CONF_FILE:=$NGINX_CONF_DIR/nginx.conf} # nginx config file
: ${NGINXCONFWATCH_ENABLED:=false} # (true|**false**) enable nginx web server dynamic configuration update watch

: ${PHPINFO:=false}                   # (true|**false**) if true, then automatically create a **info.php** file into webroot/.test/info.php
: ${DOCUMENTROOT:=/var/www/html}      # (**directory path**) default webroot path
: ${PHP_PREFIX:=/usr/local/php}       # PHP base path
: ${PHP_INI_DIR:=$PHP_PREFIX/etc/php} # php ini files directory
: ${PHP_CONF:="$PHP_INI_DIR/php.ini"} # path of php.ini file
: ${PHP_MODULES_ENABLED:=""}
: ${PHP_MODULES_DISABLED:=""}

## smtp options
: ${domain:="$HOSTNAME"}                # local hostname
: ${from:="root@localhost.localdomain"} # default From email address
: ${host:="localhost"}                  # remote smtp server
: ${port:=25}                           # smtp port
: ${tls:="off"}                         # (**on**|**off**) enable tls
: ${starttls:="off"}                    # (**on**|**off**) enable starttls
: ${username:=""}                       # username for auth smtp server
: ${password:=""}                       # password for auth smtp server
: ${timeout:=3600}                      # connection timeout
```

### Create a `Dockerfile` in your project

```dockerfile
FROM izdock/frontend:latest
COPY ./public-html/ /var/www/html/
```

Then, run the commands to build and run the Docker image:

```console
$ docker build --pull --rm --build-arg APP_VER=7.4.27 -t frontend:7.4.27 .
$ docker run --rm -it -e PHPFPM_ENABLED=false -e ENTRYPOINT_TINI=false -p 8080:80 frontend:7.4.27
```

Visit http://localhost and you will see It works!

### Without a `Dockerfile`

If you don't want to include a `Dockerfile` in your project, it is sufficient to do the following:

```console
$ docker run -dit --name my-webapp -p 80:80 -v "$PWD":/var/www/html izdock/frontend
```

### Configuration

To customize the configuration of the httpd server, just `COPY` your custom configuration in as `/etc/apache2/conf-enabled/local.conf`.

```dockerfile
FROM izdock/frontend
COPY ./my-httpd.conf /etc/apache2/conf-enabled/local.conf
```

#### SSL/HTTPS

If you want to run your web traffic over SSL, the simplest setup is to `COPY` or mount (`-v`) your `server.crt` and `server.key` into `/etc/apache2/conf-enabled/` and then customize the `/etc/apache2/conf-enabled/ssl.conf` by removing the comment symbol from the following lines:

```apacheconf
...
#LoadModule socache_shmcb_module modules/mod_socache_shmcb.so
...
#LoadModule ssl_module modules/mod_ssl.so
...
#Include conf-enabled/ssl.conf
...
```

The `conf-enabled/ssl.conf` configuration file will use the certificate files previously added and tell the daemon to also listen on port 443. Be sure to also add something like `-p 443:443` to your `docker run` to forward the https port.

This could be accomplished with a `sed` line similar to the following:

```dockerfile
RUN sed -i \
		-e 's/^#\(Include .*httpd-ssl.conf\)/\1/' \
		-e 's/^#\(LoadModule .*mod_ssl.so\)/\1/' \
		-e 's/^#\(LoadModule .*mod_socache_shmcb.so\)/\1/' \
		conf/httpd.conf
```

# Quick reference

-	**Where to get help**:
	[InitZero Corporate Support](https://www.initzero.it/)

-	**Where to file issues**:
	[https://github.com/ugoviti](https://github.com/ugoviti)

-	**Maintained by**:
	[Ugo Viti](https://github.com/ugoviti)

-	**Supported architectures**:
	[`amd64`]

-	**Supported Docker versions**:
	[the latest release](https://github.com/docker/docker-ce/releases/latest) (down to 1.6 on a best-effort basis)

## `httpd:<version>`

This is the defacto image. If you are unsure about what your needs are, you probably want to use this one. It is designed to be used both as a throw away container (mount your source code and start the container to start your app), as well as the base to build other images off of.

# License

View [Apache license information](https://www.apache.org/licenses/) and [PHP license information](http://php.net/license/index.php) and for the software contained in this image.

As with all Docker images, these likely also contain other software which may be under other licenses (such as Bash, etc from the base distribution, along with any direct or indirect dependencies of the primary software being contained).

Some additional license information which was able to be auto-detected might be found in [the `repo-info` repository's `httpd/` directory](https://github.com/docker-library/repo-info/tree/master/repos/httpd).

As for any pre-built image usage, it is the image user's responsibility to ensure that any use of this image complies with any relevant licenses for all software contained within.
