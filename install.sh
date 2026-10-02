#!/usr/bin/env bash
# Usage: ./install.sh            add aliasx to ~/.bashrc and ~/.zshrc
#        ./install.sh --uninstall remove it
set -eu

ROOT="$(cd "$(dirname "$0")" && pwd)"
MARK="# aliasx"
LINE="[ -f \"$ROOT/aliasx.sh\" ] && . \"$ROOT/aliasx.sh\" $MARK"

for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
  [ -f "$rc" ] || continue
  if [ "${1:-}" = "--uninstall" ]; then
    grep -v "$MARK\$" "$rc" > "$rc.aliasx.tmp" || true
    mv "$rc.aliasx.tmp" "$rc"
    echo "removed from $rc"
  elif grep -q "$MARK\$" "$rc"; then
    echo "already in $rc"
  else
    printf '\n%s\n' "$LINE" >> "$rc"
    echo "added to $rc"
  fi
done

if [ "${1:-}" != "--uninstall" ]; then
  echo
  echo "Checking for name conflicts..."
  # Run in a clean bash so only aliasx and your PATH are considered.
  ALIASX_ROOT="$ROOT" bash -c '. "$ALIASX_ROOT/aliasx.sh" && aliasx conflicts'
  echo "Rename or disable with ALIASX_DISABLE if a conflict matters to you."
fi
