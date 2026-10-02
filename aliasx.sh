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

# Modules per profile. core and hints always load.
ALIASX_PROFILES="
minimal: nav files git
backend: nav files git docker api db dev dotenv net util nginx tools
devops: nav files git docker podman k8s infra ops cloud net util remote dotenv nginx tools
sysadmin: nav files git admin system net remote ops util nginx tools
"

. "$ALIASX_ROOT/aliases/core.sh"

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
  _aliasx_name="$(basename "$_aliasx_mod" .sh)"
  case "$_aliasx_name" in core) continue ;; hints) ;; *)
    if [ -n "$_aliasx_want" ]; then
      case " $_aliasx_want " in *" $_aliasx_name "*) ;; *) continue ;; esac
    fi ;;
  esac
  case " ${ALIASX_DISABLE:-} " in
    *" $_aliasx_name "*) continue ;;
  esac
  . "$_aliasx_mod"
done

# shellcheck disable=SC2116
for _aliasx_name in $(echo "${ALIASX_ENABLE:-}"); do
  _aliasx_mod="$ALIASX_ROOT/optional/$_aliasx_name.sh"
  if [ -f "$_aliasx_mod" ]; then
    . "$_aliasx_mod"
  else
    echo "aliasx: unknown optional module '$_aliasx_name'" >&2
  fi
done
# An alias with the same name as an aliasx function (e.g. from oh-my-zsh)
# would shadow it; drop the alias so the aliasx version runs.
# shellcheck disable=SC2013
for _aliasx_name in $(sed -n 's/^[[:space:]]*function \([A-Za-z_][A-Za-z0-9_-]*\) {.*/\1/p' "$ALIASX_ROOT"/aliases/*.sh); do
  unalias "$_aliasx_name" 2>/dev/null
done

# Your own aliases load last so they win (aliasx add).
[ -f "$ALIASX_LOCAL" ] && . "$ALIASX_LOCAL"
unset _aliasx_mod _aliasx_name _aliasx_want _aliasx_p _aliasx_m
