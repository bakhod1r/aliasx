. "$ALIASX_ROOT/tests/helpers.sh"

ALIASX_DISABLE="nav" . "$ALIASX_ROOT/aliasx.sh"
refute_alias ll

unset ALIASX_DISABLE
. "$ALIASX_ROOT/aliasx.sh"
assert_alias ll

# install.sh: idempotent, writes to temp HOME only
fake="$(mktemp -d)"
touch "$fake/.bashrc" "$fake/.zshrc"
HOME="$fake" bash "$ALIASX_ROOT/install.sh" >/dev/null
HOME="$fake" bash "$ALIASX_ROOT/install.sh" >/dev/null
assert_eq "$(grep -c 'aliasx.sh' "$fake/.bashrc")" "1" "bashrc source line once"
assert_eq "$(grep -c 'aliasx.sh' "$fake/.zshrc")" "1" "zshrc source line once"

HOME="$fake" bash "$ALIASX_ROOT/install.sh" --uninstall >/dev/null
assert_eq "$(grep -c 'aliasx' "$fake/.bashrc")" "0" "uninstall cleans bashrc"
rm -rf "$fake"
finish
