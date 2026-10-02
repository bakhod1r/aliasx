. "$ALIASX_ROOT/tests/helpers.sh"
. "$ALIASX_ROOT/aliasx.sh"
tmp="$(mktemp -d)"; cd "$tmp" || exit 1

for f in envset envget envdel envls; do assert_function "$f"; done

# insert into new .env
envset env=hi >/dev/null
assert_eq "$(cat .env)" "env=hi" "insert creates .env"

# update in place, other lines untouched, order kept
printf 'A=1\nenv=old\n# comment\nB=2' > .env
envset env=hi >/dev/null
assert_eq "$(cat .env)" "$(printf 'A=1\nenv=hi\n# comment\nB=2')" "update in place"

# insert new key at end (file had no trailing newline)
envset C=3 >/dev/null
assert_eq "$(tail -n 1 .env)" "C=3" "insert at end"
assert_eq "$(grep -c '^B=2$' .env)" "1" "previous last line intact"

# export KEY= form is updated too
printf 'export TOKEN=a\n' > .env
envset TOKEN=b >/dev/null
assert_eq "$(cat .env)" "export TOKEN=b" "export form updated"

# values with spaces, =, backslash, &
envset 'URL=postgres://u:p@h/db?a=1&b=2' >/dev/null
envset 'MSG="hello world"' >/dev/null
envset 'P=a\nb' >/dev/null
assert_eq "$(envget URL)" "postgres://u:p@h/db?a=1&b=2" "value with = and &"
assert_eq "$(envget MSG)" '"hello world"' "quoted value kept"
assert_eq "$(envget P)" 'a\nb' "backslash kept literally"

# similar key names are not touched
printf 'KEY=1\nKEY2=2\nMYKEY=3\n' > .env
envset KEY=9 >/dev/null
assert_eq "$(cat .env)" "$(printf 'KEY=9\nKEY2=2\nMYKEY=3')" "exact key match only"

# other file
envset X=1 config.env >/dev/null
assert_eq "$(cat config.env)" "X=1" "custom file"

# delete and list
envdel KEY2 >/dev/null
assert_eq "$(envls)" "$(printf 'KEY\nMYKEY')" "envdel + envls"

# permissions kept
chmod 600 .env; envset NEW=1 >/dev/null
assert_eq "$(perms .env | cut -d' ' -f1)" "600" "permissions kept"

# bad input
envset >/dev/null 2>&1; assert_eq "$?" "2" "no args"
envset novalue >/dev/null 2>&1; assert_eq "$?" "2" "missing ="
envset '1BAD=x' >/dev/null 2>&1; assert_eq "$?" "2" "invalid key"
envget MISSING >/dev/null 2>&1; assert_eq "$?" "1" "missing key"

cd /; command rm -r "$tmp"
finish
