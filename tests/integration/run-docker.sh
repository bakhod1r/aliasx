#!/usr/bin/env bash
# Start real services in an Ubuntu container and run services.sh against them.
set -eu
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
DOCKER="$(command -v docker || echo /Applications/Docker.app/Contents/Resources/bin/docker)"
"$DOCKER" run --rm -v "$ROOT":/src:ro ubuntu:24.04 bash -c '
  set -e
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -qq >/dev/null
  apt-get install -y -qq postgresql redis-server nginx curl openssl python3 netcat-openbsd >/dev/null 2>&1
  pg_ctlcluster 16 main start
  su postgres -c "psql -qc \"ALTER USER postgres PASSWORD '"'"'pw'"'"'\""
  redis-server --daemonize yes >/dev/null
  nginx
  cp -r /src /w
  bash /w/tests/integration/services.sh
'
