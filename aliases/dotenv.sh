# .env files: insert or update KEY=VALUE without opening an editor.
# Default file is ./.env; pass another path as the last argument.

# envset KEY=VALUE [FILE] — insert or update KEY in .env
#   $ envset DB_HOST=localhost
#   updated DB_HOST in .env
function envset {
  case "${1:-}" in
    [A-Za-z_]*=*) ;;
    *) echo "Usage: envset KEY=VALUE [file]" >&2; return 2 ;;
  esac
  _k="${1%%=*}"
  case "$_k" in *[!A-Za-z0-9_]*) echo "envset: invalid key '$_k'" >&2; unset _k; return 2 ;; esac
  _f="${2:-.env}"
  if [ -f "$_f" ] && grep -Eq "^(export[[:space:]]+)?$_k=" "$_f"; then
    _t="$(mktemp)" || return 1
    ALIASX_K="$_k" ALIASX_V="${1#*=}" awk '
      { m = $0; sub(/^export[ \t]+/, "", m) }
      index(m, ENVIRON["ALIASX_K"] "=") == 1 && !done {
        p = (m == $0) ? "" : substr($0, 1, length($0) - length(m))
        print p ENVIRON["ALIASX_K"] "=" ENVIRON["ALIASX_V"]; done = 1; next }
      { print }' "$_f" > "$_t" && cat "$_t" > "$_f"
    command rm -f "$_t"; unset _t
    echo "updated $_k in $_f"
  else
    [ -s "$_f" ] && [ "$(tail -c 1 -- "$_f")" != "" ] && printf '\n' >> "$_f"
    printf '%s\n' "$1" >> "$_f"
    echo "added $_k to $_f"
  fi
  unset _k _f
}

# envget KEY [FILE] — print value of KEY from .env
#   $ envget DB_HOST
#   localhost
function envget {
  [ "$#" -ge 1 ] || { echo "Usage: envget KEY [file]" >&2; return 2; }
  ALIASX_K="$1" awk '
    { m = $0; sub(/^export[ \t]+/, "", m) }
    index(m, ENVIRON["ALIASX_K"] "=") == 1 { print substr(m, length(ENVIRON["ALIASX_K"]) + 2); f = 1; exit }
    END { exit !f }' "${2:-.env}"
}

# envdel KEY [FILE] — remove KEY from .env
#   $ envdel DB_HOST
#   removed DB_HOST from .env
function envdel {
  [ "$#" -ge 1 ] || { echo "Usage: envdel KEY [file]" >&2; return 2; }
  _f="${2:-.env}"; _t="$(mktemp)" || return 1
  ALIASX_K="$1" awk '{ m = $0; sub(/^export[ \t]+/, "", m) } index(m, ENVIRON["ALIASX_K"] "=") != 1' "$_f" > "$_t" &&
    cat "$_t" > "$_f" && echo "removed $1 from $_f"
  command rm -f "$_t"; unset _t _f
}

# envls [FILE] — list keys in .env (values hidden)
#   $ envls
#   DB_HOST
#   DB_PORT
#   JWT_SECRET
function envls { sed -n -E 's/^(export[[:space:]]+)?([A-Za-z_][A-Za-z0-9_]*)=.*/\2/p' "${1:-.env}"; }
