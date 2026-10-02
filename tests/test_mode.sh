# shellcheck disable=SC2216  # stubs and piped answers are intentional
. "$ALIASX_ROOT/tests/helpers.sh"
. "$ALIASX_ROOT/aliasx.sh"

tmp="$(mktemp -d)"; cd "$tmp" || exit 1

# Default: normal mode, rm untouched.
assert_eq "$(aliasx mode)" "normal" "default mode"
touch a; rm a; [ -e a ] && { echo "  normal rm failed"; _failures=$((_failures + 1)); }

aliasx mode safe >/dev/null
assert_eq "$(aliasx mode)" "safe" "mode switched"

touch b "c d"
echo n | rm b >/dev/null 2>&1
[ -e b ] || { echo "  rm deleted after n"; _failures=$((_failures + 1)); }
echo "" | rm b "c d" >/dev/null 2>&1
[ -e b ] && { echo "  rm kept file after Enter (default Y)"; _failures=$((_failures + 1)); }
[ -e "c d" ] && { echo "  rm kept file with space"; _failures=$((_failures + 1)); }
touch e; echo y | rm -f e >/dev/null 2>&1
[ -e e ] && { echo "  rm -f after y failed"; _failures=$((_failures + 1)); }

out="$(touch f; echo n | rm f 2>&1)"
case "$out" in *f*"[Y/n]"*) ;; *) echo "  prompt missing target or [Y/n]: $out"; _failures=$((_failures + 1)) ;; esac

aliasx mode normal >/dev/null
touch g; rm g; [ -e g ] && { echo "  rm after normal failed"; _failures=$((_failures + 1)); }

ALIASX_MODE=safe; . "$ALIASX_ROOT/aliasx.sh"
assert_eq "$(aliasx mode)" "safe" "ALIASX_MODE=safe at load"
aliasx mode normal >/dev/null

aliasx mode bogus >/dev/null 2>&1; assert_eq "$?" "2" "unknown mode"

cd / && command rm -rf "$tmp"
finish
