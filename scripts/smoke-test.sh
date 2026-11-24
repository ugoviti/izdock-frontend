#!/bin/bash
## Quick checks on a built image before it gets published.
## usage: scripts/smoke-test.sh IMAGE
set -euo pipefail

image="$1"
name="smoke-test-$$"
# modules every variant must load (pdo_odbc is not built on PHP 7.4)
required="bcmath bz2 exif gd gmp memcached mysqli opcache pdo_mysql pdo_pgsql pdo_sqlite redis soap sockets xdebug xsl zip"

fail() { echo "FAIL: $*" >&2; exit 1; }
cleanup() { docker rm -f "$name" >/dev/null 2>&1 || true; }
trap cleanup EXIT

echo "== $image"

# PHP starts without warnings (a missing shared library shows up here)
out="$(docker run --rm --entrypoint php "$image" -v 2>&1)"
echo "$out" | head -1
echo "$out" | grep -qi "warning" && fail "PHP startup warnings: $out"

# compiled modules are present (pecl modules are built but not enabled by default)
present="$(docker run --rm --entrypoint sh "$image" -c \
  'php -m; ls "$(php -r "echo ini_get(\"extension_dir\");")"' 2>&1 | tr 'A-Z' 'a-z' | sed 's/^zend opcache$/opcache/; s/\.so$//')"
# pecl modules this variant does not build yet (PHP_PECL_SKIP in docker-bake.hcl)
skip="$(docker inspect -f '{{range .Config.Env}}{{println .}}{{end}}' "$image" | sed -n 's/^PHP_PECL_SKIP=//p')"
for m in $required; do
  case " $skip " in *" $m "*) echo "module $m: skipped (PHP_PECL_SKIP)"; continue ;; esac
  echo "$present" | grep -qx "$m" || fail "module $m missing"
done
echo "modules: ok"

# no SSH server: openssh-server would be auto-enabled by runit and bind port 22
docker run --rm --entrypoint sh "$image" -c \
  '! dpkg -s openssh-server >/dev/null 2>&1 && [ ! -e /usr/sbin/sshd ] && [ ! -e /etc/runit/runsvdir/default/ssh ]' \
  || fail "openssh-server is installed"
echo "sshd: absent"

# PHP 7.4 has no fix for CVE-2026-115560: session upload progress must stay off
upload_progress="$(docker run --rm --entrypoint php "$image" -r \
  'echo PHP_MAJOR_VERSION . "." . PHP_MINOR_VERSION . " " . var_export((bool) ini_get("session.upload_progress.enabled"), true);')"
if [[ "$upload_progress" == "7.4 "* ]]; then
  [[ "$upload_progress" == "7.4 false" ]] || fail "session.upload_progress.enabled is on (CVE-2026-115560)"
  echo "CVE-2026-115560 mitigation: ok"
fi

# Apache + PHP-FPM serve a PHP page (and do not leak its source)
docker run -d --name "$name" "$image" >/dev/null
for _ in $(seq 1 30); do
  docker exec "$name" curl -fs -o /dev/null http://localhost/ 2>/dev/null && break
  sleep 1
done
docker exec "$name" sh -c 'echo "<?php echo \"SMOKE-OK \" . PHP_VERSION;" > /var/www/html/smoke-test.php'
body="$(docker exec "$name" curl -fs http://localhost/smoke-test.php || true)"
[[ "$body" == SMOKE-OK* ]] || fail "PHP page not executed, got: ${body:-<empty>}"
echo "http: $body"
