# shellcheck disable=SC2016  # stubs and piped answers are intentional
. "$ALIASX_ROOT/tests/helpers.sh"

stubs="$(mktemp -d)"
log="$stubs/calls.log"
for t in git docker redis-cli nginx; do
  printf '#!/bin/sh\necho "%s $*" >> "%s"\n' "$t" "$log" > "$stubs/$t"; chmod +x "$stubs/$t"
done
PATH="$stubs:$PATH"
ALIASX_ENABLE="modern dangerous"; . "$ALIASX_ROOT/aliasx.sh"

# Wrong confirmation: nothing destructive runs.
echo "no" | gpristine >/dev/null 2>&1
grep -q 'reset --hard' "$log" 2>/dev/null && { echo "  gpristine ran without confirmation"; _failures=$((_failures + 1)); }

echo "n" | dprune >/dev/null 2>&1
grep -q 'system prune' "$log" 2>/dev/null && { echo "  dprune ran without confirmation"; _failures=$((_failures + 1)); }

echo "nope" | docker-prune-all >/dev/null 2>&1
grep -q 'prune --all' "$log" 2>/dev/null && { echo "  docker-prune-all ran without confirmation"; _failures=$((_failures + 1)); }

# Right confirmation runs it.
echo "PRUNE-DOCKER" | docker-prune-all >/dev/null 2>&1
grep -q 'system prune --all' "$log" || { echo "  docker-prune-all did not run after confirmation"; _failures=$((_failures + 1)); }

echo "no" | redis-flush >/dev/null 2>&1
grep -q 'flushdb' "$log" && { echo "  redis-flush ran without confirmation"; _failures=$((_failures + 1)); }

# nginx: failing config test blocks reload.
printf '#!/bin/sh\necho "nginx $*" >> "%s"\n[ "$1" = -t ] && exit 1\nexit 0\n' "$log" > "$stubs/nginx"
ngr >/dev/null 2>&1; assert_eq "$?" "1" "ngr stops on bad config"
grep -q 'reload' "$log" && { echo "  ngr reloaded broken config"; _failures=$((_failures + 1)); }

# Usage errors return 2.
mkcd >/dev/null 2>&1; assert_eq "$?" "2" "mkcd without args"
ff >/dev/null 2>&1;   assert_eq "$?" "2" "ff without args"
up x >/dev/null 2>&1; assert_eq "$?" "2" "up with non-number"

# Filenames with spaces.
tmp="$(mktemp -d)"; cd "$tmp" || exit 1
mkcd "a dir"
assert_eq "$(basename "$(pwd)")" "a dir" "mkcd with spaces"
echo x > "my file"; backup "my file" >/dev/null
ls "my file".bak.* >/dev/null 2>&1 || { echo "  backup with spaces"; _failures=$((_failures + 1)); }

cd / && rm -rf "$tmp" "$stubs"
finish
