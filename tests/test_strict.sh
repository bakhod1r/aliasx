# shellcheck disable=SC2016  # $1 expands in the child shell on purpose
. "$ALIASX_ROOT/tests/helpers.sh"
# Loading must survive strict shell options users or scripts may have set.
if [ -n "${ZSH_VERSION:-}" ]; then
  out="$(zsh -f -c 'setopt errexit nounset; . "$1"; echo loaded; aliasx version >/dev/null; echo ran' _ "$ALIASX_ROOT/aliasx.sh" 2>&1)"
else
  out="$(bash -c 'set -eu; . "$1"; echo loaded; aliasx version >/dev/null; echo ran' _ "$ALIASX_ROOT/aliasx.sh" 2>&1)"
fi
case "$out" in *loaded*ran*) ;; *) echo "  strict mode load failed: $out"; _failures=$((_failures + 1)) ;; esac

# Load-time budget: 5 loads under 1.5s (about 300ms each, generous for slow CI).
start="$(date +%s)"
sh_="$(basename "${ZSH_VERSION:+zsh}${BASH_VERSION:+bash}")"
"$sh_" -c 'for i in 1 2 3 4 5; do . "$1"; done' _ "$ALIASX_ROOT/aliasx.sh" >/dev/null 2>&1
took=$(( $(date +%s) - start ))
[ "$took" -le 2 ] || { echo "  5 loads took ${took}s"; _failures=$((_failures + 1)); }
finish
