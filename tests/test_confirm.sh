. "$ALIASX_ROOT/tests/helpers.sh"
stubs="$(mktemp -d)"; log="$stubs/calls.log"
for t in sudo systemctl tmux pmset; do
  printf '#!/bin/sh\necho "%s $*" >> "%s"\n' "$t" "$log" > "$stubs/$t"; chmod +x "$stubs/$t"
done
PATH="$stubs:$PATH"
. "$ALIASX_ROOT/aliasx.sh"

for f in sys-reboot sys-poweroff sys-suspend tk; do assert_function "$f"; done

# Default (Enter) and "n" do nothing.
for f in sys-reboot sys-poweroff sys-suspend; do
  echo "" | "$f" >/dev/null 2>&1
  echo "n" | "$f" >/dev/null 2>&1
done
echo "n" | tk work >/dev/null 2>&1
[ -s "$log" ] && { echo "  ran without yes:"; cat "$log"; _failures=$((_failures + 1)); }

# "y" runs it.
echo y | sys-reboot >/dev/null 2>&1
grep -q 'systemctl reboot' "$log" || { echo "  sys-reboot did not run after y"; _failures=$((_failures + 1)); }
echo y | tk work >/dev/null 2>&1
grep -q 'tmux kill-session -t work' "$log" || { echo "  tk did not run after y"; _failures=$((_failures + 1)); }

# Prompt shows [y/N].
out="$(echo n | sys-poweroff 2>&1)"
case "$out" in *"[y/N]"*) ;; *) echo "  prompt missing [y/N]: $out"; _failures=$((_failures + 1)) ;; esac

command rm -r "$stubs"
finish
