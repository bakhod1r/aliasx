. "$ALIASX_ROOT/tests/helpers.sh"
stubs="$(mktemp -d)"
for t in git docker kubectl; do printf '#!/bin/sh\n' > "$stubs/$t"; chmod +x "$stubs/$t"; done
PATH="$stubs:$PATH"

# minimal: nav, files, git only
ALIASX_PROFILE=minimal; . "$ALIASX_ROOT/aliasx.sh"
assert_alias ll; assert_alias gs
refute_alias d; refute_alias k
assert_function aliasx  # core always loads
assert_eq "$(aliasx profile)" "minimal" "aliasx profile shows active"

# profiles combine
unalias d k gs 2>/dev/null
ALIASX_PROFILE="minimal devops"; . "$ALIASX_ROOT/aliasx.sh"
assert_alias k; assert_alias d

# backend has docker and api but not k8s
unalias d k 2>/dev/null; unset -f hget 2>/dev/null
ALIASX_PROFILE=backend; . "$ALIASX_ROOT/aliasx.sh"
assert_alias d; assert_function hget; refute_alias k

# unknown profile warns, loads everything
unalias d k 2>/dev/null
ALIASX_PROFILE=nope; out="$(. "$ALIASX_ROOT/aliasx.sh" 2>&1)"
case "$out" in *"unknown profile 'nope'"*) ;; *) echo "  no warning: $out"; _failures=$((_failures + 1)) ;; esac

# listing
for p in minimal backend devops sysadmin full; do
  case "$(aliasx profiles)" in *"$p:"*) ;; *) echo "  profiles list missing $p"; _failures=$((_failures + 1)) ;; esac
done
command rm -r "$stubs"
finish
