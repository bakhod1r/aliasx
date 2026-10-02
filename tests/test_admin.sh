. "$ALIASX_ROOT/tests/helpers.sh"
stubs="$(mktemp -d)"; log="$stubs/calls.log"
for t in sudo systemctl journalctl last lsof; do
  printf '#!/bin/sh\necho "%s $*" >> "%s"\n' "$t" "$log" > "$stubs/$t"; chmod +x "$stubs/$t"
done
PATH="$stubs:$PATH"
. "$ALIASX_ROOT/aliasx.sh"

for a in logins reboots deleted; do assert_alias "$a"; done
for f in userinfo bigfiles svc svcr svcstop failedlogins; do assert_function "$f"; done

# svcr asks, then restarts with sudo
: > "$log"; echo n | svcr nginx >/dev/null 2>&1
grep -q restart "$log" && { echo "  svcr ran without y"; _failures=$((_failures + 1)); }
echo y | svcr nginx >/dev/null 2>&1
grep -q 'sudo systemctl restart nginx' "$log" || { echo "  svcr after y"; _failures=$((_failures + 1)); }
svcr >/dev/null 2>&1; assert_eq "$?" "2" "svcr usage"

# bigfiles finds files over the limit
tmp="$(mktemp -d)"; cd "$tmp" || exit 1
dd if=/dev/zero of=big.bin bs=1024 count=2048 2>/dev/null; echo x > small.txt
out="$(bigfiles . 1M)"
case "$out" in *big.bin*) ;; *) echo "  bigfiles missed big.bin: $out"; _failures=$((_failures + 1)) ;; esac
case "$out" in *small.txt*) echo "  bigfiles listed small file"; _failures=$((_failures + 1)) ;; esac

# userinfo shows current user
case "$(userinfo "$(id -un)")" in *"uid="*) ;; *) echo "  userinfo"; _failures=$((_failures + 1)) ;; esac
userinfo nosuchuser_zz >/dev/null 2>&1; assert_eq "$?" "1" "userinfo unknown user"

cd /; command rm -r "$tmp" "$stubs"
finish
