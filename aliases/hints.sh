# Hints: typing an aliasx name then Space shows what it does.
# Any other word (e.g. port) lists related aliasx commands. ALIASX_FIND=0 turns lists off.
#   zsh: shown under the prompt while typing.
#   bash 4+: printed above the prompt. bash 3 (macOS default): use aliasx why NAME.
# Turn off: ALIASX_DISABLE="hints"

if [ -n "${ZSH_VERSION:-}" ]; then
  [[ -o interactive ]] || return 0
  # Remember what Space did before us. On a second load Space is already ours,
  # so keep the value saved the first time.
  _aliasx_space_now="$(bindkey ' ' 2>/dev/null)"; _aliasx_space_now="${_aliasx_space_now##* }"
  if [ "$_aliasx_space_now" != _aliasx_hint_space ]; then
    case "$_aliasx_space_now" in ''|undefined-key) _aliasx_space_now=self-insert ;; esac
    _aliasx_space_orig="$_aliasx_space_now"
  fi
  : "${_aliasx_space_orig:=self-insert}"
  unset _aliasx_space_now

  function _aliasx_hint_space {
    local _hint
    if [[ -n $LBUFFER && $LBUFFER != *[[:space:]]* ]]; then
      if _hint="$(aliasx_hint "$LBUFFER")"; then
        zle -M "$_hint"
      elif [[ ${ALIASX_FIND:-1} != 0 ]] && _hint="$(aliasx_find "${LBUFFER%\?}" | head -8)" && [[ -n $_hint ]]; then
        zle -M "related commands:"$'\n'"$_hint"
      fi
    fi
    zle "$_aliasx_space_orig"
  }
  zle -N _aliasx_hint_space
  bindkey ' ' _aliasx_hint_space

elif [ -n "${BASH_VERSION:-}" ] && [ "${BASH_VERSINFO[0]}" -ge 4 ]; then
  case "$-" in *i*) ;; *) return 0 ;; esac

  function _aliasx_hint_space {
    local _left="${READLINE_LINE:0:READLINE_POINT}" _hint
    READLINE_LINE="$_left ${READLINE_LINE:READLINE_POINT}"
    READLINE_POINT=$((READLINE_POINT + 1))
    case "$_left" in ''|*[[:space:]]*) return ;; esac
    _hint="$(aliasx_hint "$_left")" || _hint="$(aliasx_find "${_left%\?}" | head -8)"
    [ -n "$_hint" ] || return
    printf '\033[2m%s\033[0m\n' "$_hint" >&2
  }
  bind -x '" ": _aliasx_hint_space'
fi
