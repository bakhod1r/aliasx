# Hints: typing an aliasx name then Space shows what it does.
# Any other word (e.g. port) lists related aliasx commands. ALIASX_FIND=0 turns lists off.
#   zsh: shown under the prompt while typing.
#   bash 4+: printed above the prompt. bash 3 (macOS default): use aliasx why NAME.
# Turn off: ALIASX_DISABLE="hints"

# _aliasx_hint_style TEXT — each hint line dim, the command name in bold
function _aliasx_hint_style {
  local _line _name
  while IFS= read -r _line; do
    _name="${_line%% *}"
    if [ "$_name" = "$_line" ]; then printf '\033[2m%s\033[0m\n' "$_line"
    else printf '\033[1m%s\033[22;2m%s\033[0m\n' "$_name" "${_line#"$_name"}"; fi
  done <<< "$1"
}

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

  # _aliasx_hint_show TEXT — under the prompt, or above it when zsh-autocomplete
  # is loaded: its live list redraws below the prompt and would wipe the hint.
  function _aliasx_hint_show {
    if (( ${#${(k)functions[(I).autocomplete*]}} )); then
      zle -I
      { echo; _aliasx_hint_style "$1"; echo; } >/dev/tty
    else
      zle -M $'\n'"$1"$'\n'
    fi
  }

  function _aliasx_hint_space {
    local _hint
    if [[ -n $LBUFFER && $LBUFFER != *[[:space:]]* ]]; then
      if _hint="$(aliasx_hint "$LBUFFER")"; then
        _aliasx_hint_show "$_hint"
      elif [[ ${ALIASX_FIND:-1} != 0 ]] && _hint="$(aliasx_find "${LBUFFER%\?}" | head -8)" && [[ -n $_hint ]]; then
        _aliasx_hint_show "related commands:"$'\n'"$_hint"
      fi
    fi
    zle "$_aliasx_space_orig"
  }
  zle -N _aliasx_hint_space
  bindkey ' ' _aliasx_hint_space

elif [ -n "${BASH_VERSION:-}" ] && [ "${BASH_VERSINFO[0]}" -ge 4 ]; then
  case "$-" in *i*) ;; *) return 0 ;; esac

  # Rows the last hint took on screen. Reset at every new prompt so a hint
  # is only erased while it still sits right above the line being typed.
  _aliasx_hint_rows=0
  function _aliasx_hint_reset { _aliasx_hint_rows=0; }
  case ";${PROMPT_COMMAND:-};" in
    *";_aliasx_hint_reset;"*) ;;
    *) PROMPT_COMMAND="_aliasx_hint_reset${PROMPT_COMMAND:+;$PROMPT_COMMAND}" ;;
  esac

  function _aliasx_hint_space {
    local _left="${READLINE_LINE:0:READLINE_POINT}" _hint _line _cols="${COLUMNS:-80}" _rows=0
    READLINE_LINE="$_left ${READLINE_LINE:READLINE_POINT}"
    READLINE_POINT=$((READLINE_POINT + 1))
    case "$_left" in ''|*[[:space:]]*) return ;; esac
    _hint="$(aliasx_hint "$_left")" || _hint="$(aliasx_find "${_left%\?}" | head -8)"
    [ -n "$_hint" ] || return
    # Erase the previous hint so only one is on screen. bash 5.1+ clears the
    # input line before running bind -x, so the old hint is right above.
    if [ "$_aliasx_hint_rows" -gt 0 ] && { [ "${BASH_VERSINFO[0]}" -gt 5 ] ||
        { [ "${BASH_VERSINFO[0]}" -eq 5 ] && [ "${BASH_VERSINFO[1]}" -ge 1 ]; }; }; then
      printf '\r\033[%dA\033[J' "$_aliasx_hint_rows" >&2
    fi
    while IFS= read -r _line; do
      _rows=$((_rows + (${#_line} + _cols - 1) / _cols + (${#_line} == 0)))
    done <<< "$_hint"
    # Blank line above and below sets the hint apart from output and prompt.
    _aliasx_hint_rows=$((_rows + 2))
    { echo; _aliasx_hint_style "$_hint"; echo; } >&2
  }
  bind -x '" ": _aliasx_hint_space'
fi
