#!/usr/bin/env bash
# Integration tests against real PostgreSQL, Redis and nginx (no stubs).
# Runs as root in a throwaway Ubuntu container; see tests/integration/run-docker.sh.
set -u
shopt -s expand_aliases
ALIASX_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
. "$ALIASX_ROOT/tests/helpers.sh"
. "$ALIASX_ROOT/aliasx.sh"
check() {
  _label="$(printf '%s ' "$@" | tr '\n' ' ' | cut -c1-70)"
  if "$@"; then echo "ok   $_label"; else echo "FAIL $_label"; _failures=$((_failures + 1)); fi
}
has_text() { case "$1" in *"$2"*) return 0 ;; *) echo "  wanted [$2] in: ${1:0:200}"; return 1 ;; esac; }
cd "$(mktemp -d)" || exit 1

echo "--- PostgreSQL"
export PGHOST=127.0.0.1 PGUSER=postgres PGPASSWORD=pw PGDATABASE=postgres
check has_text "$(pgready)" "accepting connections"
check has_text "$(pgls)" "template1"
pgq postgres "CREATE DATABASE shop" >/dev/null
pgq shop "CREATE TABLE orders(id int); INSERT INTO orders VALUES (1),(2),(3)" >/dev/null
check has_text "$(pgq shop 'SELECT count(*) FROM orders')" "3"
check has_text "$(pgsize)" "shop"
check has_text "$(pgconns)" "pid"
dump="$(pgdump shop)"
check test -s "$dump"
pgq postgres "CREATE DATABASE shop_copy" >/dev/null
pgrestore "$dump" shop_copy >/dev/null 2>&1
check has_text "$(pgq shop_copy 'SELECT count(*) FROM orders')" "3"

echo "--- Redis"
check has_text "$(rping)" "PONG"
redis-cli set session:a 1 >/dev/null; redis-cli set session:b 2 >/dev/null; redis-cli set other 3 >/dev/null
check has_text "$(rget session:a)" "1"
keys="$(rkeys 'session:*' | sort | tr '\n' ' ')"
check has_text "$keys" "session:a session:b"
case "$keys" in *other*) echo "FAIL rkeys pattern leaked"; _failures=$((_failures + 1)) ;; esac
check has_text "$(rinfo)" "redis_version"
check has_text "$(rmem)" "used_memory"

echo "--- nginx"
check has_text "$(ngt 2>&1)" "syntax is ok"
check has_text "$(httpcode http://127.0.0.1/)" "200"
check has_text "$(timing http://127.0.0.1/)" "status:  200"
check has_text "$(hget http://127.0.0.1/ 2>&1)" "nginx"
check has_text "$(waitport 127.0.0.1 80 5)" "is up"
# broken config: ngr must refuse and keep the old config serving
cp /etc/nginx/nginx.conf /tmp/nginx.conf.good
echo "this is not valid;" >> /etc/nginx/nginx.conf
out="$(ngr 2>&1)"; rc=$?
check test "$rc" -ne 0
check has_text "$out" "nothing reloaded"
check has_text "$(httpcode http://127.0.0.1/)" "200"
cp /tmp/nginx.conf.good /etc/nginx/nginx.conf
check ngr

echo "--- TLS"
selfcert dev.local >/dev/null
check has_text "$(certfile dev.local.crt)" "days left: 36"

finish
