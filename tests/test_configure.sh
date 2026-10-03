# shellcheck disable=SC2016  # snippets run inside bash -c
. "$ALIASX_ROOT/tests/helpers.sh"
tmp="$(mktemp -d)"
stubs="$(mktemp -d)"
for t in git docker kubectl; do printf '#!/bin/sh\n' > "$stubs/$t"; chmod +x "$stubs/$t"; done
PATH="$stubs:$PATH"
unset ALIASX_PROFILE ALIASX_DISABLE ALIASX_ENABLE ALIASX_MODE ALIASX_CONF_KEYS

# == Loader reads ~/.aliasx.conf
ALIASX_CONF="$tmp/conf"
cat > "$ALIASX_CONF" <<'EOF'
# aliasx config
ALIASX_PROFILE="minimal"
ALIASX_ENABLE="modern"
ALIASX_MODE="safe"
EVIL="x"
ALIASX_DISABLE="$(touch /tmp/aliasx-pwned)"
EOF
. "$ALIASX_ROOT/aliasx.sh"
assert_eq "$(aliasx profile)" "minimal" "conf sets profile"
assert_eq "$ALIASX_MODE" "safe" "conf sets mode"
assert_eq "${EVIL:-}" "" "unknown keys ignored"
assert_eq "${ALIASX_DISABLE:-}" "" "unsafe value ignored"
refute_alias k
[ -e /tmp/aliasx-pwned ] && { echo "  conf value was executed"; _failures=$((_failures + 1)); }

# env set before loading wins over conf
unset ALIASX_PROFILE ALIASX_MODE ALIASX_ENABLE ALIASX_CONF_KEYS
ALIASX_PROFILE=devops; . "$ALIASX_ROOT/aliasx.sh"
assert_eq "$(aliasx profile)" "devops" "env wins over conf"

# re-loading picks up a changed conf (values came from conf, not env)
unset ALIASX_PROFILE ALIASX_CONF_KEYS
printf 'ALIASX_PROFILE="minimal"\n' > "$ALIASX_CONF"; . "$ALIASX_ROOT/aliasx.sh"
printf 'ALIASX_PROFILE="backend"\n' > "$ALIASX_CONF"; . "$ALIASX_ROOT/aliasx.sh"
assert_eq "$(aliasx profile)" "backend" "reload sees new conf"
_aliasx_mode_set normal

# == Configure TUI logic (bash script, tested headless)
cfg() { ALIASX_CONF="$tmp/conf" bash -c ". '$ALIASX_ROOT/bin/aliasx-configure'; $1"; }

out="$(cfg 'cfg_load; echo "$PROF|$MODE"')"
assert_eq "$out" "backend|normal" "load existing conf"

out="$(cfg 'PROF=full; prof_toggle backend; prof_toggle devops; echo "$PROF"')"
assert_eq "$out" "backend devops" "picking a role drops full"
out="$(cfg 'PROF=backend; prof_toggle backend; echo "$PROF"')"
assert_eq "$out" "full" "empty selection falls back to full"
out="$(cfg 'PROF=backend; prof_toggle full; echo "$PROF"')"
assert_eq "$out" "full" "full clears roles"

out="$(cfg 'PROF=minimal; active_mods | tr "\n" " "')"
assert_eq "$out" "nav files git hints " "modules of a profile"

# keys: step 1 (modules) toggle git off, then save step writes the file
out="$(cfg 'PROF=minimal; OFF=; ON=; MODE=normal; STEP=1; CUR=2; handle_key " "; echo "$OFF"')"
assert_eq "$out" "git" "space toggles module off"
out="$(cfg 'STEP=0; handle_key right; handle_key right; echo "$STEP"; handle_key left; echo "$STEP"')"
assert_eq "$(echo "$out" | tr "\n" " ")" "2 1 " "arrows move between steps"
out="$(cfg 'STEP=0; CUR=0; handle_key down; handle_key down; handle_key up; echo "$CUR"')"
assert_eq "$out" "1" "up/down move cursor"
cfg 'STEP=0; handle_key q' ; assert_eq "$?" "1" "q quits"

out="$(cfg 'PROF=minimal; OFF="git docker"; ON=modern; MODE=safe; render_conf')"
case "$out" in *'ALIASX_PROFILE="minimal"'*'ALIASX_DISABLE="git"'*'ALIASX_ENABLE="modern"'*'ALIASX_MODE="safe"'*) ;;
  *) echo "  bad render: $out"; _failures=$((_failures + 1)) ;; esac

cfg 'PROF=devops; OFF=; ON=; MODE=normal; STEP=4; handle_key enter' >/dev/null
assert_eq "$?" "0" "enter on last step saves"
grep -q 'ALIASX_PROFILE="devops"' "$tmp/conf" || { echo "  conf not written"; _failures=$((_failures + 1)); }
grep -q 'ALIASX_PROFILE="backend"' "$tmp/conf.bak" || { echo "  no backup"; _failures=$((_failures + 1)); }

draw="$(cfg 'cfg_load; STEP=0; CUR=0; draw')"
case "$draw" in *Profile*full*minimal*) ;; *) echo "  draw missing items"; _failures=$((_failures + 1)) ;; esac

# not a terminal: refuses instead of hanging
out="$(bash "$ALIASX_ROOT/bin/aliasx-configure" </dev/null 2>&1)"; rc=$?
assert_eq "$rc" "1" "needs a tty"
# aliasx set is the same as configure: needs a tty here
out="$(aliasx set </dev/null 2>&1)"
case "$out" in *"needs an interactive terminal"*) ;; *) echo "  aliasx set: $out"; _failures=$((_failures + 1)) ;; esac
case "$(aliasx 2>&1)" in *configure*) ;; *) echo "  usage lacks configure"; _failures=$((_failures + 1)) ;; esac

command rm -rf "$tmp" "$stubs"
finish
