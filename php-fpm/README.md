# Description
Production ready PHP-FPM (FastCGI Process Manager) image based on Debian (Slim) Linux + izsendmail for MTA logging

# Supported tags
-	`7.4.X-BUILD`, `7.4.X`, `7.4`, `7`, `latest`
-	`7.3.X-BUILD`, `7.3.X`, `7.3`
-	`7.2.X-BUILD`, `7.2.X`, `7.2`
-	`7.1.X-BUILD`, `7.1.X`, `7.1`

Where **X** is the patch version number, and **BUILD** is the build number (look into project [Tags](/repository/docker/izdock/php-fpm/tags/) page to discover the latest versions)

# Dockerfile
- https://github.com/ugoviti/izdock-httpd/blob/master/php-fpm/Dockerfile

# Features
- Small image footprint (all images are based on [izdock httpd image](/repository/docker/izdock/httpd))
- The Apache HTTPD Web Server is present but unused from this image
- You can use `izdock/php-fpm` as sidecar image (Docker Compose or Kubernetes) for NGINX or Apache configured with MPM Event and Reverse Proxy for PHP pages
- Build from scratch PHP interpreter with all modules included, plus external modules (igbinary apcu msgpack opcache memcached redis xdebug phpiredis realpath_turbo tarantool)
- Included izsendmail bash script as wrapper for `msmtp` for PHP logging of outgoing emails
- Many customizable variables to use

# What is php-fpm?

PHP-FPM (FastCGI Process Manager) is an alternative PHP FastCGI implementation with some additional features useful for sites of any size, especially busier sites.

These features include:

- Adaptive process spawning (NEW!)
- Basic statistics (ala Apache's mod_status) (NEW!)
- Advanced process management with graceful stop/start
- Ability to start workers with different uid/gid/chroot/environment and different php.ini (replaces safe_mode)
- Stdout & stderr logging
- Emergency restart in case of accidental opcode cache destruction
- Accelerated upload support
- Support for a "slowlog"
- Enhancements to FastCGI, such as fastcgi_finish_request() - a special function to finish request & flush all data while continuing to do something time-consuming (video converting, stats processing, etc.)

... and much more.

It was not designed with virtual hosting in mind (large amounts of pools) however it can be adapted for any usage model.


# How to use this image.

TODO

### Create a `Dockerfile` in your project

TODO

### Without a `Dockerfile`

If you don't want to include a `Dockerfile` in your project, it is sufficient to do the following:

```console
$ docker run -dit --name my-webapp -p 8080:80 -v "$PWD":/var/www/localhost/htdocs izdock/php-fpm
```

### Configuration

TODO

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

## `izdock/php-fpm:<version>`

:FIXME:

# License

View [license information](http://php.net/license/index.php) for the software contained in this image.

As with all Docker images, these likely also contain other software which may be under other licenses (such as Bash, etc from the base distribution, along with any direct or indirect dependencies of the primary software being contained).

As for any pre-built image usage, it is the image user's responsibility to ensure that any use of this image complies with any relevant licenses for all software contained within.
