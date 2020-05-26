# Description
Production ready Apache HTTPD Web Server + mod_php + izsendmail for MTA logging

# Supported tags
* `2.4.43-php7.4.X-BUILD, 2.4.43-php7.4.X, 2.4-php7.4, php7.4, 2, 2.4, 2.4.43, latest`
* `2.4.43-php7.3.X-BUILD, 2.4.43-php7.3.X, 2.4-php7.3, php7.3`
* `2.4.43-php7.2.X-BUILD, 2.4.43-php7.2.X, 2.4-php7.2, php7.2`
* `2.4.43-php7.1.X-BUILD, 2.4.43-php7.1.X, 2.4-php7.1, php7.1`

Where **X** is the patch version number, and **BUILD** is the build number (look into project [Tags](/repository/docker/izdock/httpd/tags/) page to discover the latest versions)

# Dockerfile
- https://github.com/ugoviti/izdock-httpd/blob/master/Dockerfile

# Features
- Small image footprint
- Based on official [httpd](/_/httpd/) and [Debian Buster-Slim](/_/debian/) image
- OnDemand configurable Apache MPM Worker (use **event** or **worker** for best scalability and memory optimization, PHP get automatically disabled because is not ZTS compiled). The default Apache MPM Worker is **prefork** (if prefork is used, mod_php will be enabled by default)
- Build from scratch PHP as NTS (Not Threat Safe) and many useful php modules included, plus external modules (`igbinary apcu msgpack opcache memcached redis xdebug phpiredis realpath_turbo tarantool`)
- Included izsendmail bash script as wrapper for `msmtp` used for smarthost delivery of mail messages sent from PHP scripts using sendmail() function
- Automatically generate Self Signed SSL certificates if not found into configuration to avoid apache startup problems
- Integrated PHP-FPM support using runit service manager
- Many customizable variables to use

# What is httpd?
The Apache HTTP Server, colloquially called Apache, is a Web server application notable for playing a key role in the initial growth of the World Wide Web. Originally based on the NCSA HTTPd server, development of Apache began in early 1995 after work on the NCSA code stalled. Apache quickly overtook NCSA HTTPd as the dominant HTTP server, and has remained the most popular HTTP server in use since April 1996.

> [wikipedia.org/wiki/Apache_HTTP_Server](http://en.wikipedia.org/wiki/Apache_HTTP_Server)

![logo](https://www.apache.org/img/asf_logo.png)

# How to use this image.

This image only contains Apache httpd with the defaults from official httpd repository and the PHP already installed (**mod_php**) with many modules already compiled as **libphp**.

# Environment default variables

You can change the default behaviour using the following variables (in bold the default values):

**Apache Web Server:**
```
: ${MULTISERVICE:=false}          # (true|**false**) enable multiple service manager
: ${UMASK:=0002}                  # (**0002**) default umask when creating new files
: ${SERVERNAME:=$HOSTNAME}        # (**$HOSTNAME**) default web server hostname
: ${HTTPD_ENABLED:=true}          # (**true**|false) # enable apache web server
: ${HTTPD_MOD_SSL:=false}         # (true|**false**) enable apache module mod_ssl
: ${HTTPD_CONF_DIR:=/etc/apache2} # (**/etc/apache2**) # apache config dir
: ${HTTPD_MPM:=prefork}           # (event|worker|**prefork**) # default apache mpm worker to use
: ${PHP_ENABLED:=true}            # (**true**|false) enable apache module mod_php
: ${PHPFPM_ENABLED:=false}        # (true|**false**) enable php-fpm service
: ${PHPINFO:=false}               # (true|**false**) if true, then automatically create a **info.php** file into webroot
: ${DOCUMENTROOT:=/var/www/localhost/htdocs} # (**directory path**) default webroot path
```

**MSMTP MTA Agent:**
```
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
FROM izdock/httpd:2.4-php7.2
COPY ./public-html/ /usr/local/apache2/htdocs/
```

Then, run the commands to build and run the Docker image:

```console
$ docker build -t my-httpd .
$ docker run -dit --name my-webapp -p 8080:80 my-httpd
```

Visit http://localhost:8080 and you will see It works!

### Without a `Dockerfile`

If you don't want to include a `Dockerfile` in your project, it is sufficient to do the following:

```console
$ docker run -dit --name my-webapp -p 8080:80 -v "$PWD":/var/www/localhost/htdocs izdock/httpd:2.4-php7.2
```

### Configuration

To customize the configuration of the httpd server, just `COPY` your custom configuration in as `/etc/apache2/conf/httpd.conf`.

```dockerfile
FROM izdock/httpd:2.4-php7.2
COPY ./my-httpd.conf /etc/apache2/conf/httpd.conf
```

#### SSL/HTTPS

If you want to run your web traffic over SSL, the simplest setup is to `COPY` or mount (`-v`) your `server.crt` and `server.key` into `/etc/apache2/conf/` and then customize the `/etc/apache2/conf/httpd.conf` by removing the comment symbol from the following lines:

```apacheconf
...
#LoadModule socache_shmcb_module modules/mod_socache_shmcb.so
...
#LoadModule ssl_module modules/mod_ssl.so
...
#Include conf/extra/httpd-ssl.conf
...
```

The `conf/extra/httpd-ssl.conf` configuration file will use the certificate files previously added and tell the daemon to also listen on port 443. Be sure to also add something like `-p 443:443` to your `docker run` to forward the https port.

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

This image is based on the popular [Alpine Linux project](http://alpinelinux.org), available in [the `alpine` official image](https://hub.docker.com/_/alpine). Alpine Linux is much smaller than most distribution base images (~5MB), and thus leads to much slimmer images in general.

This variant is highly recommended when final image size being as small as possible is desired. The main caveat to note is that it does use [musl libc](http://www.musl-libc.org) instead of [glibc and friends](http://www.etalabs.net/compare_libcs.html), so certain software might run into issues depending on the depth of their libc requirements. However, most software doesn't have an issue with this, so this variant is usually a very safe choice. See [this Hacker News comment thread](https://news.ycombinator.com/item?id=10782897) for more discussion of the issues that might arise and some pro/con comparisons of using Alpine-based images.

To minimize image size, it's uncommon for additional related tools (such as `git` or `bash`) to be included in Alpine-based images. Using this image as a base, add the things you need in your own Dockerfile (see the [`alpine` image description](https://hub.docker.com/_/alpine/) for examples of how to install packages if you are unfamiliar).

# License

View [Apache license information](https://www.apache.org/licenses/) and [PHP license information](http://php.net/license/index.php) and for the software contained in this image.

As with all Docker images, these likely also contain other software which may be under other licenses (such as Bash, etc from the base distribution, along with any direct or indirect dependencies of the primary software being contained).

Some additional license information which was able to be auto-detected might be found in [the `repo-info` repository's `httpd/` directory](https://github.com/docker-library/repo-info/tree/master/repos/httpd).

As for any pre-built image usage, it is the image user's responsibility to ensure that any use of this image complies with any relevant licenses for all software contained within.