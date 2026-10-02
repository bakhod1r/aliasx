. "$ALIASX_ROOT/tests/helpers.sh"
# Simulate oh-my-zsh style aliases that share names with aliasx functions.
alias gpristine='echo OMZ'
alias mkcd='echo OMZ'
out="$(. "$ALIASX_ROOT/aliasx.sh" 2>&1)"
case "$out" in *"parse error"*|*"defining function"*) echo "  load failed: $out"; _failures=$((_failures + 1)) ;; esac
. "$ALIASX_ROOT/aliasx.sh" 2>/dev/null
refute_alias mkcd           # aliasx function wins
assert_function mkcd
finish
