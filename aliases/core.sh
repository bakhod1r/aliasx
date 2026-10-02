# Core: helpers, terminal and the aliasx command. Always loaded.

case "$(uname -s)" in
  Darwin) ALIASX_OS=macos ;;
  Linux)  ALIASX_OS=linux ;;
  *)      ALIASX_OS=other ;;
esac
export ALIASX_OS

# has CMD — true when CMD is installed
#   $ has docker && echo yes
#   yes
function has { command -v "$1" >/dev/null 2>&1; }

# aliasx_hint NAME — one-line explanation of an aliasx alias or function
#   $ aliasx_hint gs
#   gs → git status --short --branch · short status with branch
function aliasx_hint {
  _h="$(awk -v n="$1" '
    /^[[:space:]]*# / {
      l = $0; sub(/^[[:space:]]*# /, "", l); d = " — "; i = index(l, d)
      if (i) { head = substr(l, 1, i - 1); split(head, w, " ")
               if (w[1] == n) { print "F\t" head "\t" substr(l, i + length(d)); exit } }
      next }
    /alias / {
      s = substr($0, index($0, "alias ") + 6); if (substr(s, 1, 3) == "-- ") s = substr(s, 4)
      if (substr(s, 1, index(s, "=") - 1) == n) { c = index($0, "  # "); print "A\t" substr($0, c + 4); exit } }
  ' "$ALIASX_ROOT"/aliases/*.sh "$ALIASX_ROOT"/optional/*.sh "$ALIASX_LOCAL" 2>/dev/null)"
  case "$_h" in
    A*)
      alias "$1" >/dev/null 2>&1 || { unset _h; return 1; }
      if [ -n "${ZSH_VERSION:-}" ]; then eval '_e=${aliases[$1]}'
      else
        _e="$(alias "$1")"
        _e="${_e#*=}"; _e="${_e#\'}"; _e="${_e%\'}"
        _e="$(printf '%s' "$_e" | sed "s/'\\\\''/'/g")"
      fi
      printf '%s → %s · %s\n' "$1" "$_e" "${_h#*	}" ;;
    F*)
      typeset -f "$1" >/dev/null 2>&1 || { unset _h; return 1; }
      _h="${_h#*	}"; printf '%s · %s\n' "${_h%%	*}" "${_h#*	}" ;;
    *) unset _h; return 1 ;;
  esac
  unset _h _e
}

# aliasx_find WORD — loaded aliasx commands whose name or description mentions WORD
#   $ aliasx_find port
#   ports [PORT] · listening TCP ports, or who listens on PORT
#   freeport PORT · kill what listens on PORT after y/N
function aliasx_find {
  [ -n "${1:-}" ] || { echo "Usage: aliasx find <word>" >&2; return 2; }
  _found=1
  # Names never contain spaces, so word splitting is safe here.
  # shellcheck disable=SC2013
  for _n in $(awk -v w="$1" '
      function has(t) { t = " " tolower(t); gsub(/[^a-z0-9]/, " ", t); return index(t, " " w) }
      BEGIN { w = tolower(w) }
      /^[[:space:]]*# [A-Za-z][A-Za-z0-9_-]*( [^—]*)? — / {
        l = $0; sub(/^[[:space:]]*# /, "", l); split(l, p, " ")
        if (index(tolower(p[1]), w)) print 0, p[1]; else if (has(l)) print 1, p[1]; next }
      /alias (-- )?[^ =]+=[\x27"]/ && !/^[[:space:]]*#/ {
        s = substr($0, index($0, "alias ") + 6); if (substr(s, 1, 3) == "-- ") s = substr(s, 4)
        n = substr(s, 1, index(s, "=") - 1); c = index($0, "  # ")
        if (index(tolower(n), w)) print 0, n; else if (c && has(substr($0, c))) print 1, n }
    ' "$ALIASX_ROOT"/aliases/*.sh "$ALIASX_ROOT"/optional/*.sh "$ALIASX_LOCAL" 2>/dev/null | sort -s -n -k1,1 | awk '!seen[$2]++ {print $2}'); do
    case "$_n" in _*|aliasx*|has|yesno) continue ;; esac
    aliasx_hint "$_n" 2>/dev/null && _found=0
  done
  unset _n; return $_found
}

# == Your own aliases (aliasx add / rm / mine)
ALIASX_LOCAL="${ALIASX_LOCAL:-$HOME/.aliasx.local.sh}"

function _aliasx_local_add {
  [ "$#" -ge 2 ] || { echo "Usage: aliasx add <name> <command> [description]" >&2; return 2; }
  case "$1" in ''|*[!A-Za-z0-9_.-]*) echo "aliasx: invalid name '$1'" >&2; return 2 ;; esac
  _q="$(printf '%s' "$2" | sed "s/'/'\\\\''/g")"
  _line="alias $1='$_q'  # ${3:-$2}"
  if _hit="$(_aliasx_on_path "$1")"; then echo "aliasx: note, '$1' hides $_hit" >&2; fi
  touch "$ALIASX_LOCAL"
  _t="$(mktemp)" && grep -v "^alias[[:space:]]$1=" "$ALIASX_LOCAL" > "$_t"; echo "$_line" >> "$_t"
  cat "$_t" > "$ALIASX_LOCAL"; command rm -f "$_t"
  eval "$_line"
  echo "saved $1 in $ALIASX_LOCAL"
  unset _q _line _hit _t
}

function _aliasx_local_rm {
  [ -n "$1" ] || { echo "Usage: aliasx rm <name>" >&2; return 2; }
  grep -q "^alias[[:space:]]$1=" "$ALIASX_LOCAL" 2>/dev/null || { echo "aliasx: '$1' is not one of your aliases" >&2; return 1; }
  _t="$(mktemp)" && grep -v "^alias[[:space:]]$1=" "$ALIASX_LOCAL" > "$_t"; cat "$_t" > "$ALIASX_LOCAL"; command rm -f "$_t"
  unalias "$1" 2>/dev/null
  echo "removed $1"; unset _t
}

# Names that replace a standard command on purpose (see docs).
ALIASX_INTENDED="ls grep egrep fgrep rm cat top fd bat dc"

function _aliasx_names {
  awk '
    /^[[:space:]]*# [A-Za-z][A-Za-z0-9_-]*( [^—]*)? — / { l = $0; sub(/^[[:space:]]*# /, "", l); split(l, p, " "); print p[1]; next }
    /alias (-- )?[^ =]+=[\x27"]/ && !/^[[:space:]]*#/ {
      s = substr($0, index($0, "alias ") + 6); if (substr(s, 1, 3) == "-- ") s = substr(s, 4)
      print substr(s, 1, index(s, "=") - 1) }
  ' "$ALIASX_ROOT"/aliases/*.sh "$ALIASX_ROOT"/optional/*.sh | sort -u
}

# _aliasx_on_path NAME — print first program NAME found on PATH
function _aliasx_on_path {
  _p="$PATH:"
  while [ -n "$_p" ]; do
    _d="${_p%%:*}"; _p="${_p#*:}"
    if [ -n "$_d" ] && [ -x "$_d/$1" ] && [ ! -d "$_d/$1" ]; then echo "$_d/$1"; unset _p _d; return 0; fi
  done
  unset _p _d; return 1
}

# Report aliasx names that hide a program on PATH or clash with your rc files.
function _aliasx_conflicts {
  _found=1
  for _n in $(_aliasx_names); do
    case "$_n" in _*|aliasx*|-|.*) continue ;; esac
    case " $ALIASX_INTENDED " in
      *" $_n "*) ;;
      *) if _hit="$(_aliasx_on_path "$_n")"; then echo "$_n  hides program $_hit"; _found=0; fi ;;
    esac
    for _rc in "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.bash_aliases"; do
      [ -f "$_rc" ] || continue
      if grep -Eq "^[[:space:]]*(alias[[:space:]]+${_n}=|(function[[:space:]]+)?${_n}[[:space:]]*\(\))" "$_rc" 2>/dev/null; then
        echo "$_n  also defined in $_rc"; _found=0
      fi
    done
  done
  unset _n _rc _hit
  [ "$_found" = 0 ] || echo "no conflicts"
  unset _found
}

# == Terminal
alias c='clear'  # clear screen
alias now='date "+%Y-%m-%d %H:%M:%S"'  # current date and time
alias week='date "+%V"'  # ISO week number
alias path='echo "$PATH" | tr ":" "\n"'  # PATH, one entry per line
alias e='${EDITOR:-vi}'  # open in your editor
alias envg='env | sort | grep -i'  # search environment variables

# reload — re-read ~/.bashrc or ~/.zshrc
#   $ reload
#   (rc file re-read, new aliases active)
function reload {
  if [ -n "${ZSH_VERSION:-}" ]; then . "$HOME/.zshrc"; else . "$HOME/.bashrc"; fi
}

# yesno PROMPT — ask [y/N]; true only on y/yes
#   $ yesno "Deploy?" && ./deploy.sh
#   Deploy? [y/N] y
function yesno {
  printf '%s [y/N] ' "$1" >&2
  read -r _a
  case "$_a" in y|Y|yes|YES) unset _a; return 0 ;; esac
  echo "Cancelled." >&2; unset _a; return 1
}

# == Modes
# safe: rm lists what it will delete and asks [Y/n]. normal: plain rm.
# Persist with ALIASX_MODE=safe in your rc file.
function _aliasx_mode_set {
  case "$1" in
    safe)
      function rm {
        [ "$#" -gt 0 ] || { command rm; return; }
        _t="" _o=1
        for _x in "$@"; do
          if [ "$_o" = 1 ] && [ "$_x" = "--" ]; then _o=0
          elif [ "$_o" = 1 ] && [ "${_x#-}" != "$_x" ]; then :
          else _t="$_t '$_x'"; fi
        done
        printf 'rm: delete%s? [Y/n] ' "$_t" >&2
        read -r _a
        case "$_a" in n|N|no|NO) echo "Cancelled." >&2; unset _t _o _x _a; return 1 ;; esac
        unset _t _o _x _a
        command rm "$@"
      } ;;
    normal) unset -f rm 2>/dev/null ;;
    *) echo "Usage: aliasx mode [safe|normal]" >&2; return 2 ;;
  esac
  ALIASX_MODE="$1"
}
_aliasx_mode_set "${ALIASX_MODE:-normal}"

# aliasx COMMAND — find, why, add, rm, mine, mode, profile, conflicts, list, modules
#   $ aliasx why lni
#   lni → ln -i · link, ask before overwriting
function aliasx {
  case "${1:-}" in
    modules)
      for _f in "$ALIASX_ROOT"/aliases/*.sh; do basename "$_f" .sh; done
      for _f in "$ALIASX_ROOT"/optional/*.sh; do echo "$(basename "$_f" .sh) (optional)"; done
      unset _f ;;
    list)
      _f="$ALIASX_ROOT/aliases/${2:-}.sh"
      [ -f "$_f" ] || _f="$ALIASX_ROOT/optional/${2:-}.sh"
      [ -n "${2:-}" ] && [ -f "$_f" ] || { echo "Usage: aliasx list <module>" >&2; return 2; }
      grep -E '^[[:space:]]*(alias |# [a-z][a-z0-9_-]* ?.*— )' "$_f" | sed 's/^[[:space:]]*//'
      unset _f ;;
    check)
      shift
      [ "$#" -gt 0 ] || { echo "Usage: aliasx check <name>..." >&2; return 2; }
      for _n in "$@"; do
        if alias "$_n" >/dev/null 2>&1; then alias "$_n"
        elif typeset -f "$_n" >/dev/null 2>&1; then echo "$_n: function"
        elif command -v "$_n" >/dev/null 2>&1; then echo "$_n: command $(command -v "$_n")"
        else echo "$_n: available"; fi
      done
      unset _n ;;
    profile)
      echo "${ALIASX_PROFILE:-full}" ;;
    profiles)
      printf '%s\n' "$ALIASX_PROFILES" | sed '/^$/d'
      echo "full: everything (default)" ;;
    add)
      shift; _aliasx_local_add "$@" ;;
    rm)
      _aliasx_local_rm "${2:-}" ;;
    mine)
      [ -f "$ALIASX_LOCAL" ] && grep '^alias ' "$ALIASX_LOCAL" ;;
    conflicts)
      _aliasx_conflicts ;;
    find)
      aliasx_find "${2:-}" ;;
    why)
      [ -n "${2:-}" ] || { echo "Usage: aliasx why <name>" >&2; return 2; }
      aliasx_hint "$2" ;;
    mode)
      if [ -z "${2:-}" ]; then echo "$ALIASX_MODE"
      else _aliasx_mode_set "$2" && echo "aliasx mode: $ALIASX_MODE"; fi ;;
    *)
      echo "Usage: aliasx modules | list <module> | check <name>... | add <name> <cmd> [desc] | rm <name> | mine | conflicts | profile | profiles | find <word> | why <name> | mode [safe|normal]" >&2
      return 2 ;;
  esac
}
