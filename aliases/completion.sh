# Tab completion for the aliasx command.
# zsh already completes aliases like dc or k as their real commands
# (unless you set complete_aliases). bash: k gets kubectl completion in k8s.sh.

# _aliasx_complete_words POS PREV — candidates for word POS after PREV
function _aliasx_complete_words {
  if [ "$1" -le 1 ]; then
    echo "modules list check find why mode add rm mine conflicts profile profiles"
    return
  fi
  case "$2" in
    list) for _f in "$ALIASX_ROOT"/aliases/*.sh "$ALIASX_ROOT"/optional/*.sh; do basename "$_f" .sh; done; unset _f ;;
    mode) echo "normal safe" ;;
    why|check) _aliasx_names ;;
    rm) [ -f "$ALIASX_LOCAL" ] && sed -n 's/^alias[[:space:]]\([^=]*\)=.*/\1/p' "$ALIASX_LOCAL" ;;
  esac
}

if [ -n "${ZSH_VERSION:-}" ]; then
  # zsh-only syntax, kept in eval so bash can parse this file.
  eval 'function _aliasx_zsh_complete {
    local -a words_
    words_=(${(f)"$(_aliasx_complete_words $((CURRENT - 1)) "${words[2]}" | tr " " "\n")"})
    compadd -a words_
  }'
  (( $+functions[compdef] )) && compdef _aliasx_zsh_complete aliasx
elif [ -n "${BASH_VERSION:-}" ]; then
  function _aliasx_bash_complete {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    # shellcheck disable=SC2207
    COMPREPLY=($(compgen -W "$(_aliasx_complete_words "$COMP_CWORD" "${COMP_WORDS[1]}")" -- "$cur"))
  }
  complete -F _aliasx_bash_complete aliasx
fi
