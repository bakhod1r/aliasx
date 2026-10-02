. "$ALIASX_ROOT/tests/helpers.sh"
stubs="$(mktemp -d)"
for t in uv poetry composer php rails bundle dotnet; do printf '#!/bin/sh\n' > "$stubs/$t"; chmod +x "$stubs/$t"; done
PATH="$stubs:$PATH"
. "$ALIASX_ROOT/aliasx.sh"

# git extras (real git, temp repo)
for f in gwip gunwip gfixup gclean-branches gbl; do assert_function "$f"; done
tmp="$(mktemp -d)"; cd "$tmp" || exit 1
git init -q -b main . && git config user.email t@t && git config user.name t
echo a > f && git add f && git commit -qm init
echo b >> f
gwip >/dev/null
assert_eq "$(git log -1 --format=%s)" "--wip-- [skip ci]" "gwip commits"
assert_eq "$(git status --short)" "" "gwip leaves tree clean"
gunwip >/dev/null
assert_eq "$(git log -1 --format=%s)" "init" "gunwip undoes"
assert_eq "$(git status --short)" " M f" "gunwip keeps changes"
gunwip >/dev/null 2>&1; assert_eq "$?" "1" "gunwip refuses non-wip commit"

# gclean-branches: merged branch deleted after y, main kept
git commit -qam two; git branch merged-one; git branch keep-me; git checkout -q -b open; echo c >> f; git commit -qam open; git checkout -q main
echo n | gclean-branches >/dev/null 2>&1
git rev-parse -q --verify merged-one >/dev/null || { echo "  deleted without y"; _failures=$((_failures + 1)); }
echo y | gclean-branches >/dev/null 2>&1
git rev-parse -q --verify merged-one >/dev/null && { echo "  merged branch kept"; _failures=$((_failures + 1)); }
git rev-parse -q --verify open >/dev/null || { echo "  unmerged branch deleted"; _failures=$((_failures + 1)); }
git rev-parse -q --verify main >/dev/null || { echo "  main deleted"; _failures=$((_failures + 1)); }
cd /; command rm -r "$tmp"

# languages
for a in uvr uva uvs poi poa por comi comr art artm artt rsrv rdbm be dn dnr dnt dnb; do assert_alias "$a"; done
command rm -r "$stubs"
finish
