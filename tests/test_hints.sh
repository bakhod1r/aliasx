. "$ALIASX_ROOT/tests/helpers.sh"

stubs="$(mktemp -d)"
printf '#!/bin/sh\nexit 0\n' > "$stubs/git"; chmod +x "$stubs/git"
PATH="$stubs:$PATH"
. "$ALIASX_ROOT/aliasx.sh"

assert_function aliasx_hint
assert_eq "$(aliasx_hint lni)" "lni → ln -i · link, ask before overwriting" "alias hint"
assert_eq "$(aliasx_hint gs)" "gs → git status --short --branch · short status with branch" "git alias hint"
assert_eq "$(aliasx_hint ..)" ".. → cd .. · up one directory" "dotted name hint"
assert_eq "$(aliasx_hint mkcd)" "mkcd DIR · create directory and enter it" "function hint"
assert_eq "$(aliasx_hint notathing)" "" "unknown name: no hint"
aliasx_hint notathing; assert_eq "$?" "1" "unknown name returns 1"

# Names defined by the user, not aliasx, get no hint.
alias myown='echo hi'
assert_eq "$(aliasx_hint myown)" "" "foreign alias: no hint"

# aliasx why prints the same hint.
assert_eq "$(aliasx why lni)" "lni → ln -i · link, ask before overwriting" "aliasx why"

rm -rf "$stubs"
finish
