. "$ALIASX_ROOT/tests/helpers.sh"
. "$ALIASX_ROOT/aliasx.sh"
tmp="$(mktemp -d)"; cd "$tmp" || exit 1

printf 'b\n' > "my file.txt"
prepend "my file.txt" "a"
append "my file.txt" "c"
assert_eq "$(cat "my file.txt")" "$(printf 'a\nb\nc')" "prepend and append"

printf 'x\n' > s.txt
echo "top" | prepend s.txt
echo "end" | append s.txt
assert_eq "$(cat s.txt)" "$(printf 'top\nx\nend')" "text from stdin"

# File without trailing newline: append starts on a new line.
printf 'no-newline' > n.txt
append n.txt "next"
assert_eq "$(cat n.txt)" "$(printf 'no-newline\nnext')" "append after missing newline"

# Missing file: append creates it, prepend refuses.
append new.txt "hi"; assert_eq "$(cat new.txt)" "hi" "append creates file"
prepend nope.txt "x" >/dev/null 2>&1; assert_eq "$?" "1" "prepend missing file"
prepend >/dev/null 2>&1; assert_eq "$?" "2" "prepend without args"

# Permissions kept.
printf 'p\n' > perm.sh; chmod 755 perm.sh
prepend perm.sh "#!/bin/sh"
[ -x perm.sh ] || { echo "  prepend lost exec bit"; _failures=$((_failures + 1)); }

cd /; command rm -r "$tmp"
finish
