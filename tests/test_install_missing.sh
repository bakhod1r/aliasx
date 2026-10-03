. "$ALIASX_ROOT/tests/helpers.sh"
. "$ALIASX_ROOT/aliasx.sh"
stubs="$(mktemp -d)"; log="$stubs/log"
OLDPATH="$PATH"
PATH="$(isolated_path)"; base="$PATH"; PATH="$stubs:$base"

# Fake brew: logs the install and creates the program.
cat > "$stubs/brew" <<EOF
#!/bin/sh
echo "brew \$*" >> "$log"
printf '#!/bin/sh\necho "ran tree \$@"\n' > "$stubs/\$2"; chmod +x "$stubs/\$2"
EOF
chmod +x "$stubs/brew"

assert_eq "$(_aliasx_pkg_manager)" "brew" "detects brew"
assert_eq "$(_aliasx_pkg_name rg brew)" "ripgrep" "rg maps to ripgrep"
assert_eq "$(_aliasx_pkg_name fd apt)" "fd-find" "fd maps to fd-find on apt"
assert_eq "$(_aliasx_pkg_name tree brew)" "tree" "default: same name"

# "n": nothing installed, 127
out="$(echo n | _aliasx_offer_install tree -L 2 2>&1)"; rc=$?
assert_eq "$rc" "127" "declined returns 127"
case "$out" in *"tree: not installed. Install with: brew install tree?"*) ;; *) echo "  bad prompt: $out"; _failures=$((_failures + 1)) ;; esac
[ -f "$log" ] && { echo "  installed without consent"; _failures=$((_failures + 1)); }

# "y": installs, then runs the original command
out="$(echo y | _aliasx_offer_install tree -L 2 2>/dev/null)"
assert_eq "$(cat "$log")" "brew install tree" "installs on yes"
assert_eq "$out" "ran tree -L 2" "re-runs command"

# unknown package manager: just the usual message
PATH="$base"
out="$(echo y | _aliasx_offer_install nosuch 2>&1)"; rc=$?
assert_eq "$rc" "127" "no manager returns 127"
case "$out" in *"nosuch: command not found"*) ;; *) echo "  bad message: $out"; _failures=$((_failures + 1)) ;; esac

# opt-out
PATH="$stubs:$base"; : > "$log"
ALIASX_AUTOINSTALL=0
out="$(echo y | _aliasx_offer_install other 2>&1)"
assert_eq "$(cat "$log")" "" "ALIASX_AUTOINSTALL=0 disables"
unset ALIASX_AUTOINSTALL

PATH="$OLDPATH"
command rm -rf "$stubs"
finish
