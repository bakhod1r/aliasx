# aliasx — loader. Source from ~/.bashrc or ~/.zshrc.
#   ALIASX_DISABLE="git docker"     skip default modules
#   ALIASX_ENABLE="modern dangerous" load opt-in modules from optional/

if [ -z "${ALIASX_ROOT:-}" ]; then
  if [ -n "${ZSH_VERSION:-}" ]; then
    eval 'ALIASX_ROOT=${${(%):-%x}:A:h}'
  else
    ALIASX_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  fi
fi
export ALIASX_ROOT

. "$ALIASX_ROOT/aliases/core.sh"

for _aliasx_mod in "$ALIASX_ROOT"/aliases/*.sh; do
  _aliasx_name="$(basename "$_aliasx_mod" .sh)"
  [ "$_aliasx_name" = core ] && continue
  case " ${ALIASX_DISABLE:-} " in
    *" $_aliasx_name "*) continue ;;
  esac
  . "$_aliasx_mod"
done

for _aliasx_name in ${ALIASX_ENABLE:-}; do
  _aliasx_mod="$ALIASX_ROOT/optional/$_aliasx_name.sh"
  if [ -f "$_aliasx_mod" ]; then
    . "$_aliasx_mod"
  else
    echo "aliasx: unknown optional module '$_aliasx_name'" >&2
  fi
done
unset _aliasx_mod _aliasx_name
