# aliasx — loader. Source from ~/.bashrc or ~/.zshrc.
#   ALIASX_DISABLE="git docker"     skip default modules
#   ALIASX_ENABLE="modern dangerous" load opt-in modules from optional/
#   ALIASX_PROFILE="backend"         load only one role's modules (combine with spaces)

if [ -z "${ALIASX_ROOT:-}" ]; then
  if [ -n "${ZSH_VERSION:-}" ]; then
    eval 'ALIASX_ROOT=${${(%):-%x}:A:h}'
  else
    ALIASX_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  fi
fi
export ALIASX_ROOT

# ~/.aliasx.conf (written by `aliasx configure`). Only known keys with plain
# word values are read, never sourced. Variables you set before loading win;
# ones that came from the conf last time are refreshed so `reload` sees edits.
ALIASX_CONF="${ALIASX_CONF:-$HOME/.aliasx.conf}"
if [ -f "$ALIASX_CONF" ]; then
  _aliasx_keys=""
  while IFS= read -r _aliasx_l || [ -n "$_aliasx_l" ]; do
    case "$_aliasx_l" in ALIASX_PROFILE=*|ALIASX_DISABLE=*|ALIASX_ENABLE=*|ALIASX_MODE=*) ;; *) continue ;; esac
    _aliasx_k="${_aliasx_l%%=*}"; _aliasx_v="${_aliasx_l#*=}"; _aliasx_v="${_aliasx_v#\"}"; _aliasx_v="${_aliasx_v%\"}"
    case "$_aliasx_v" in *[!a-z0-9\ _-]*) continue ;; esac
    if eval "[ -z \"\${$_aliasx_k+x}\" ]" || case " ${ALIASX_CONF_KEYS:-} " in *" $_aliasx_k "*) true ;; *) false ;; esac; then
      eval "$_aliasx_k=\$_aliasx_v"; _aliasx_keys="$_aliasx_keys $_aliasx_k"
    fi
  done < "$ALIASX_CONF"
  ALIASX_CONF_KEYS="${_aliasx_keys# }"
  unset _aliasx_l _aliasx_k _aliasx_v _aliasx_keys
fi

# Modules per profile. core and hints always load.
ALIASX_PROFILES="
minimal: nav files git
backend: nav files git docker api db dev dotenv net util nginx tools
devops: nav files git docker podman k8s infra ops cloud net util remote dotenv nginx tools
sysadmin: nav files git admin system net remote ops util nginx tools
"

# "|| true": a module ending in a false test must not stop shells running with set -e.
. "$ALIASX_ROOT/aliases/core.sh" || true

_aliasx_want=""
# $(echo ...) splits words in both bash and zsh (zsh does not split $VAR).
# shellcheck disable=SC2116
for _aliasx_p in $(echo "${ALIASX_PROFILE:-}"); do
  case "$_aliasx_p" in full) _aliasx_want=""; break ;; esac
  _aliasx_m="$(printf '%s\n' "$ALIASX_PROFILES" | sed -n "s/^$_aliasx_p: //p")"
  if [ -n "$_aliasx_m" ]; then _aliasx_want="$_aliasx_want $_aliasx_m"
  else echo "aliasx: unknown profile '$_aliasx_p' (try: aliasx profiles)" >&2; _aliasx_want=""; break; fi
done

for _aliasx_mod in "$ALIASX_ROOT"/aliases/*.sh; do
  _aliasx_name="${_aliasx_mod##*/}"; _aliasx_name="${_aliasx_name%.sh}"
  case "$_aliasx_name" in core) continue ;; hints) ;; *)
    if [ -n "$_aliasx_want" ]; then
      case " $_aliasx_want " in *" $_aliasx_name "*) ;; *) continue ;; esac
    fi ;;
  esac
  case " ${ALIASX_DISABLE:-} " in
    *" $_aliasx_name "*) continue ;;
  esac
  . "$_aliasx_mod" || true
done

# shellcheck disable=SC2116
for _aliasx_name in $(echo "${ALIASX_ENABLE:-}"); do
  _aliasx_mod="$ALIASX_ROOT/optional/$_aliasx_name.sh"
  if [ -f "$_aliasx_mod" ]; then
    . "$_aliasx_mod" || true
  else
    echo "aliasx: unknown optional module '$_aliasx_name'" >&2
  fi
done
# An alias with the same name as an aliasx function (e.g. from oh-my-zsh)
# would shadow it; drop the alias so the aliasx version runs.
# shellcheck disable=SC2013
for _aliasx_name in $(sed -n 's/^[[:space:]]*function \([A-Za-z_][A-Za-z0-9_-]*\) {.*/\1/p' "$ALIASX_ROOT"/aliases/*.sh); do
  unalias "$_aliasx_name" 2>/dev/null || true
done

# Your own aliases load last so they win (aliasx add).
if [ -f "$ALIASX_LOCAL" ]; then . "$ALIASX_LOCAL" || true; fi
unset _aliasx_mod _aliasx_name _aliasx_want _aliasx_p _aliasx_m
true
