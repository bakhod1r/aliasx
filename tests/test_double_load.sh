. "$ALIASX_ROOT/tests/helpers.sh"
# Loading twice (install.sh line + oh-my-zsh plugin, or `reload`) must change nothing.
if [ -n "${ZSH_VERSION:-}" ]; then
  out="$(zsh -f -i -c 'my-space() { zle self-insert; }; zle -N my-space; bindkey " " my-space
    . "$1"; . "$1"; echo "orig=$_aliasx_space_orig"' _ "$ALIASX_ROOT/aliasx.sh" 2>&1)"
  case "$out" in *"orig=my-space"*) ;; *) echo "  Space widget lost on 2nd load: $out"; _failures=$((_failures + 1)) ;; esac
fi
. "$ALIASX_ROOT/aliasx.sh"; first="$(alias | sort | cksum)"
. "$ALIASX_ROOT/aliasx.sh"; assert_eq "$(alias | sort | cksum)" "$first" "aliases identical after 2nd load"
finish
