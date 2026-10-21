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
## ---------------------------------------------------------------------------------------
variable "PHP85_VERSION" { default = "8.5.12" } # auto: php 8.5 trixie
variable "PHP84_VERSION" { default = "8.4.27" } # auto: php 8.4 trixie
## PHP 7.4 is EOL: pinned, never updated automatically
variable "PHP74_VERSION" { default = "7.4.33" }

variable "XDEBUG_VERSION"    { default = "3.5.3" } # auto: pecl xdebug
variable "REDIS_VERSION"     { default = "6.3.0" } # auto: pecl redis
variable "MEMCACHED_VERSION" { default = "3.4.0" } # auto: pecl memcached

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
## tag scheme
##   every variant:    8.4.27-trixie  8.4-trixie  8.4.27-trixie-<commit>  8.4.27-trixie-<build>
##   default distro:   8.4.27  8.4  8.4.27-<commit>  8.4.27-<build>  (same tags used by Drone)
##   default of major: 8-trixie  8
##   latest:           latest
## ---------------------------------------------------------------------------------------
function "tags" {
  params = [version, distro, is_default, is_major_default, is_latest]
  result = flatten([
    for image in split(",", IMAGES) : flatten([
      for suffix in concat(["-${distro}"], is_default ? [""] : []) : concat(
        ["${image}:${version}${suffix}", "${image}:${minor(version)}${suffix}"],
        APP_BUILD_COMMIT != "" ? ["${image}:${version}${suffix}-${APP_BUILD_COMMIT}"] : [],
        APP_VER_BUILD != "" ? ["${image}:${version}${suffix}-${APP_VER_BUILD}"] : [],
        is_major_default ? ["${image}:${major(version)}${suffix}"] : [],
        is_latest && suffix == "" ? ["${image}:latest"] : [],
      )
    ])
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
  targets = ["php85-trixie", "php84-trixie", "php74-bullseye"]
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

## default variant: latest, 8, 8.5
target "php85-trixie" {
  inherits = ["_common"]
  args = {
    APP_VER        = PHP85_VERSION
    DEBIAN_RELEASE = "trixie"
  }
  labels = { "org.opencontainers.image.version" = PHP85_VERSION }
  tags   = tags(PHP85_VERSION, "trixie", true, true, true)
}

target "php84-trixie" {
  inherits = ["_common"]
  args = {
    APP_VER        = PHP84_VERSION
    DEBIAN_RELEASE = "trixie"
  }
  labels = { "org.opencontainers.image.version" = PHP84_VERSION }
  tags   = tags(PHP84_VERSION, "trixie", true, false, false)
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
  tags   = tags(PHP74_VERSION, "bullseye", true, true, false)
}
