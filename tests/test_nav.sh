. "$ALIASX_ROOT/tests/helpers.sh"
. "$ALIASX_ROOT/aliasx.sh"

for a in .. ... .... ..... home ll la l ldirs md rd c h path; do assert_alias "$a"; done
for f in mkcd extract backup up croot; do assert_function "$f"; done

tmp="$(mktemp -d)"
cd "$tmp" || exit 1

mkcd a/b/c
assert_eq "$(pwd -P)" "$(cd "$tmp" && pwd -P)/a/b/c" "mkcd enters new dir"

up 2
assert_eq "$(pwd -P)" "$(cd "$tmp" && pwd -P)/a" "up 2 climbs two levels"

echo hi > f.txt
backup f.txt >/dev/null
ls f.txt.bak.* >/dev/null 2>&1 || { echo "  backup copy missing"; _failures=$((_failures + 1)); }

tar -czf arc.tar.gz f.txt && rm f.txt
extract arc.tar.gz
assert_eq "$(cat f.txt)" "hi" "extract tar.gz"

extract nope.zzz >/dev/null 2>&1 && { echo "  extract should fail on unknown"; _failures=$((_failures + 1)); }

cd / && rm -rf "$tmp"
finish
