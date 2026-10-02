. "$ALIASX_ROOT/tests/helpers.sh"
. "$ALIASX_ROOT/aliasx.sh"
assert_function asroot
stubs="$(mktemp -d)"; base="$PATH"

# normal user with sudo: goes through sudo
printf '#!/bin/sh\necho "via-sudo $*"\n' > "$stubs/sudo"; chmod +x "$stubs/sudo"
printf '#!/bin/sh\necho 1000\n' > "$stubs/id"; chmod +x "$stubs/id"
PATH="$stubs:$base"
assert_eq "$(asroot echo hi)" "via-sudo echo hi" "user with sudo"

# root: runs directly
printf '#!/bin/sh\necho 0\n' > "$stubs/id"
assert_eq "$(asroot echo hi)" "hi" "root runs directly"

# no sudo installed (typical container): runs directly
printf '#!/bin/sh\necho 1000\n' > "$stubs/id"; command rm "$stubs/sudo"
PATH="$stubs:$(isolated_path)"
assert_eq "$(asroot echo hi)" "hi" "no sudo runs directly"

# no hardcoded sudo left outside `please`
PATH="$base"
bad="$(grep -n 'sudo' "$ALIASX_ROOT"/aliases/*.sh | grep -v -e 'please' -e '#' -e 'asroot()' -e 'command sudo' -e 'has sudo')"
assert_eq "$bad" "" "hardcoded sudo"
command rm -r "$stubs"
finish
