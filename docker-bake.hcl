## izdock/frontend build definition
##
## Every variant uses the same Dockerfile: the targets below only override what differs.
##
##   docker buildx bake                    # build every variant locally
##   docker buildx bake php85-trixie       # build a single variant
##   docker buildx bake --print            # show the resolved configuration and tags
##   docker buildx bake --push             # build and push (CI)

## ---------------------------------------------------------------------------------------
## versions
## lines marked "# auto:" are bumped every night by .gitea/workflows/update-versions.yml
## (scripts/update-versions.py), keep them on a single line:
##   # auto: php <minor> <debian>  -> latest php:<minor>.X-fpm-<debian> tag on Docker Hub
##   # auto: pecl <package>        -> latest stable release on pecl.php.net
## lines marked "# pending:" are workarounds waiting for a PECL release: the nightly job
## fails (after bumping the versions) as soon as a newer stable release is out, as a
## reminder to drop the workaround:
##   # pending: <package>><version> ...  -> fail when stable <package> is newer than <version>
## ---------------------------------------------------------------------------------------
variable "PHP86_VERSION" { default = "8.6.0" } # auto: php 8.6 trixie
variable "PHP85_VERSION" { default = "8.5.13" } # auto: php 8.5 trixie
variable "PHP84_VERSION" { default = "8.4.28" } # auto: php 8.4 trixie
## PHP 7.4 is EOL: pinned, never updated automatically
variable "PHP74_VERSION" { default = "7.4.33" }

variable "XDEBUG_VERSION"    { default = "3.5.3" } # auto: pecl xdebug
variable "REDIS_VERSION"     { default = "6.3.0" } # auto: pecl redis
variable "MEMCACHED_VERSION" { default = "3.4.0" } # auto: pecl memcached

## PHP 8.6 workarounds (2026-11-24), remove them when the nightly job reports a new release:
## - xdebug 3.5.3 refuses PHP >= 8.6 and memcached 3.4.0 does not compile: not built yet
## - redis 6.3.0 does not compile: 6.4.0RC1 until the 6.4.0 stable release
## - when all of them are gone, move latest and 8 to 8.6 (tags() of php86-trixie / php85-trixie)
variable "PHP86_PECL_SKIP"     { default = "xdebug memcached" } # pending: xdebug>3.5.3 memcached>3.4.0
variable "PHP86_REDIS_VERSION" { default = "6.4.0RC1" } # pending: redis>6.3.0

## ---------------------------------------------------------------------------------------
## publishing
## ---------------------------------------------------------------------------------------
## comma separated list of image names, every tag is applied to each of them
variable "IMAGES" { default = "git.quantico.srl/initzero/izdock-frontend,docker.io/izdock/frontend" }

## build metadata, set by CI through environment variables of the same name
variable "APP_VER_BUILD"    { default = "" }
variable "APP_BUILD_COMMIT" { default = "" }
variable "APP_BUILD_DATE"   { default = "" }

## ---------------------------------------------------------------------------------------
## tag scheme (same as the old Drone pipelines)
##   every variant:     8.4.27-<commit>  8.4.27-<build>  8.4.27  8.4
##   default of major:  8
##   latest:            latest
## ---------------------------------------------------------------------------------------
function "tags" {
  params = [version, is_major_default, is_latest]
  result = flatten([
    for image in split(",", IMAGES) : concat(
      APP_BUILD_COMMIT != "" ? ["${image}:${version}-${APP_BUILD_COMMIT}"] : [],
      APP_VER_BUILD != "" ? ["${image}:${version}-${APP_VER_BUILD}"] : [],
      ["${image}:${version}", "${image}:${minor(version)}"],
      is_major_default ? ["${image}:${major(version)}"] : [],
      is_latest ? ["${image}:latest"] : [],
    )
  ])
}

function "minor" {
  params = [version]
  result = join(".", slice(split(".", version), 0, 2))
}

function "major" {
  params = [version]
  result = split(".", version)[0]
}

## ---------------------------------------------------------------------------------------
## targets
## ---------------------------------------------------------------------------------------
group "default" {
  targets = ["php86-trixie", "php85-trixie", "php84-trixie", "php74-bullseye"]
}

target "_common" {
  context    = "."
  dockerfile = "Dockerfile"
  pull       = true
  args = {
    PHP_MODULE_XDEBUG_VER    = XDEBUG_VERSION
    PHP_MODULE_REDIS_VER     = REDIS_VERSION
    PHP_MODULE_MEMCACHED_VER = MEMCACHED_VERSION
    APP_VER_BUILD            = APP_VER_BUILD
    APP_BUILD_COMMIT         = APP_BUILD_COMMIT
    APP_BUILD_DATE           = APP_BUILD_DATE
  }
  labels = {
    "org.opencontainers.image.source"   = "https://git.quantico.srl/initzero/izdock-frontend"
    "org.opencontainers.image.revision" = APP_BUILD_COMMIT
  }
}

## 8.6 (latest and 8 stay on 8.5 until 8.6 has every PECL module)
target "php86-trixie" {
  inherits = ["_common"]
  args = {
    APP_VER               = PHP86_VERSION
    DEBIAN_RELEASE        = "trixie"
    PHP_MODULE_REDIS_VER  = PHP86_REDIS_VERSION
    PHP_PECL_SKIP         = PHP86_PECL_SKIP
  }
  labels = { "org.opencontainers.image.version" = PHP86_VERSION }
  tags   = tags(PHP86_VERSION, false, false)
}

## default variant: latest, 8, 8.5
target "php85-trixie" {
  inherits = ["_common"]
  args = {
    APP_VER        = PHP85_VERSION
    DEBIAN_RELEASE = "trixie"
  }
  labels = { "org.opencontainers.image.version" = PHP85_VERSION }
  tags   = tags(PHP85_VERSION, true, true)
}

target "php84-trixie" {
  inherits = ["_common"]
  args = {
    APP_VER        = PHP84_VERSION
    DEBIAN_RELEASE = "trixie"
  }
  labels = { "org.opencontainers.image.version" = PHP84_VERSION }
  tags   = tags(PHP84_VERSION, false, false)
}

## PHP 7.4 base image: official docker-library Dockerfile + PHP2Shell backport (php74/)
## used only as build input of php74-bullseye, never exported or pushed
target "php74-base" {
  context = "php74"
  pull    = true
  output  = ["type=cacheonly"]
}

target "php74-bullseye" {
  inherits = ["_common"]
  contexts = { php74-base = "target:php74-base" }
  args = {
    APP_VER             = PHP74_VERSION
    IMAGE_FROM          = "php74-base"
    ## last xdebug release supporting PHP 7
    PHP_MODULE_XDEBUG_VER = "3.1.6"
    PHP_MODULES_EXCLUDE   = "pdo_odbc"
  }
  labels = { "org.opencontainers.image.version" = PHP74_VERSION }
  tags   = tags(PHP74_VERSION, true, false)
}
