#!/usr/bin/env python3
"""Bump the versions marked with "# auto:" in docker-bake.hcl to the latest releases.

  # auto: php <minor> <debian>  -> newest php:<minor>.X-fpm-<debian> tag on Docker Hub
  # auto: pecl <package>        -> latest stable release on pecl.php.net

Versions are only ever raised, never lowered. Prints one line per change and,
when running in CI, sets the step outputs "changed" and "summary".

  # pending: <package>><version> -> workaround waiting for a PECL release

With --check-pending it only checks the "# pending:" markers: it lists the packages
with a stable release newer than the marked version and exits 1 when there is any,
so the workaround next to the marker can be removed.

Usage: scripts/update-versions.py [--dry-run | --check-pending] [path/to/docker-bake.hcl]
"""
import os
import re
import sys
import urllib.error
import urllib.request

LINE_RE = re.compile(
    r'^(?P<head>variable\s+"(?P<name>\w+)"\s*\{\s*default\s*=\s*")(?P<version>[^"]+)'
    r'(?P<tail>"\s*\}\s*#\s*auto:\s*(?P<rule>.+?))\s*$'
)


def http_get(url):
    req = urllib.request.Request(url, headers={"User-Agent": "izdock-frontend-version-check"})
    with urllib.request.urlopen(req, timeout=30) as resp:
        return resp.read().decode()


PENDING_RE = re.compile(r'^variable\s.*#\s*pending:\s*(?P<entries>.+?)\s*$')


def vtuple(version):
    return tuple(int(x) for x in version.split("."))


def docker_tag_exists(tag):
    try:
        http_get(f"https://hub.docker.com/v2/repositories/library/php/tags/{tag}")
        return True
    except urllib.error.HTTPError as err:
        if err.code == 404:
            return False
        raise


def latest_php(current, minor, debian, lookahead=5):
    """Highest php:<minor>.N-fpm-<debian> tag on Docker Hub, probing the patch
    releases after the current one (listing all tags is paginated over 1000+
    entries and gets rate limited)."""
    if not current.startswith(f"{minor}."):
        raise RuntimeError(f"version {current} does not belong to PHP {minor}")
    if not docker_tag_exists(f"{current}-fpm-{debian}"):
        raise RuntimeError(f"php:{current}-fpm-{debian} not found on Docker Hub")
    patch = int(current.split(".")[2])
    while True:
        newer = [
            p for p in range(patch + 1, patch + 1 + lookahead)
            if docker_tag_exists(f"{minor}.{p}-fpm-{debian}")
        ]
        if not newer:
            return f"{minor}.{patch}"
        patch = max(newer)


def latest_pecl(package):
    version = http_get(f"https://pecl.php.net/rest/r/{package}/stable.txt").strip()
    if not re.fullmatch(r"\d+(\.\d+)+", version):
        raise RuntimeError(f"unexpected PECL version for {package}: {version!r}")
    return version


def resolve(rule, current):
    kind, *params = rule.split()
    if kind == "php" and len(params) == 2:
        return latest_php(current, *params)
    if kind == "pecl" and len(params) == 1:
        return latest_pecl(params[0])
    raise ValueError(f"unknown auto rule: {rule!r}")


def set_output(key, value):
    path = os.environ.get("GITHUB_OUTPUT")
    if path:
        with open(path, "a") as fh:
            fh.write(f"{key}<<EOF\n{value}\nEOF\n")


def check_pending(lines):
    ready = []
    for line in lines:
        m = PENDING_RE.match(line)
        if not m:
            continue
        for entry in m.group("entries").split():
            package, _, version = entry.partition(">")
            if not package or not version:
                raise ValueError(f"bad pending entry: {entry!r}")
            latest = latest_pecl(package)
            if vtuple(latest) > vtuple(version):
                ready.append(f"{package} {latest} is out (pending marker: >{version})")
            else:
                print(f"{package}: still waiting for a release newer than {version}")
    for msg in ready:
        print(f"::error::{msg}: remove the workaround next to its '# pending:' marker in docker-bake.hcl")
    return 1 if ready else 0


def main():
    flags = {"--dry-run", "--check-pending"}
    args = [a for a in sys.argv[1:] if a not in flags]
    dry_run = "--dry-run" in sys.argv[1:]
    path = args[0] if args else "docker-bake.hcl"

    with open(path) as fh:
        lines = fh.readlines()

    if "--check-pending" in sys.argv[1:]:
        sys.exit(check_pending(lines))

    changes = []
    for i, line in enumerate(lines):
        m = LINE_RE.match(line.rstrip("\n"))
        if not m:
            continue
        current = m.group("version")
        latest = resolve(m.group("rule"), current)
        if vtuple(latest) > vtuple(current):
            lines[i] = f'{m.group("head")}{latest}{m.group("tail")}\n'
            changes.append(f'{m.group("name")}: {current} -> {latest}')
        else:
            print(f'{m.group("name")}: {current} (up to date)')

    for change in changes:
        print(change)

    if changes and not dry_run:
        with open(path, "w") as fh:
            fh.writelines(lines)

    set_output("changed", "true" if changes else "false")
    set_output("summary", "\n".join(changes))


if __name__ == "__main__":
    main()
