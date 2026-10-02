#!/usr/bin/env bash
# zsh-setup.sh — reproduce this zsh look on a new Linux or macOS machine:
#   zsh + oh-my-zsh + powerlevel10k (with setup/p10k.zsh layout)
#   plugins: git, zsh-autosuggestions, zsh-syntax-highlighting,
#            fast-syntax-highlighting, zsh-autocomplete
#   MesloLGS NF font (needed for p10k icons) and aliasx.
#
# Usage: setup/zsh-setup.sh [--no-chsh] [--no-font] [--no-aliasx]
# Safe to run again: existing pieces are kept, ~/.zshrc is backed up first.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
DO_CHSH=1 DO_FONT=1 DO_ALIASX=1
for a in "$@"; do
  case "$a" in
    --no-chsh) DO_CHSH=0 ;;
    --no-font) DO_FONT=0 ;;
    --no-aliasx) DO_ALIASX=0 ;;
    -h|--help) sed -n '2,10p' "$0"; exit 0 ;;
    *) echo "unknown option: $a" >&2; exit 2 ;;
  esac
done

say() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
has() { command -v "$1" >/dev/null 2>&1; }
SUDO=""; [ "$(id -u)" -ne 0 ] && has sudo && SUDO="sudo"

# 1. Packages: zsh, git, curl
need=()
for p in zsh git curl; do has "$p" || need+=("$p"); done
if [ "${#need[@]}" -gt 0 ]; then
  say "Installing: ${need[*]}"
  if has brew; then brew install "${need[@]}"
  elif has apt-get; then $SUDO apt-get update -qq && $SUDO apt-get install -y -qq "${need[@]}"
  elif has dnf; then $SUDO dnf install -y "${need[@]}"
  elif has pacman; then $SUDO pacman -S --noconfirm "${need[@]}"
  elif has apk; then $SUDO apk add "${need[@]}"
  else echo "Install manually: ${need[*]}" >&2; exit 1; fi
fi

# 2. oh-my-zsh (unattended: does not switch shell or start zsh)
export ZSH="${ZSH:-$HOME/.oh-my-zsh}"
if [ ! -d "$ZSH" ]; then
  say "Installing oh-my-zsh"
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
  say "oh-my-zsh already installed"
fi
CUSTOM="${ZSH_CUSTOM:-$ZSH/custom}"

# 3. Theme and plugins
clone() {  # clone URL DIR — shallow clone unless present
  if [ -d "$2/.git" ] || [ -d "$2" ]; then echo "    have $(basename "$2")"
  else git clone -q --depth=1 "$1" "$2" && echo "    got  $(basename "$2")"; fi
}
say "Theme and plugins"
clone https://github.com/romkatv/powerlevel10k.git                   "$CUSTOM/themes/powerlevel10k"
clone https://github.com/zsh-users/zsh-autosuggestions.git           "$CUSTOM/plugins/zsh-autosuggestions"
clone https://github.com/zsh-users/zsh-syntax-highlighting.git       "$CUSTOM/plugins/zsh-syntax-highlighting"
clone https://github.com/zdharma-continuum/fast-syntax-highlighting.git "$CUSTOM/plugins/fast-syntax-highlighting"
clone https://github.com/marlonrichert/zsh-autocomplete.git          "$CUSTOM/plugins/zsh-autocomplete"

# 4. Prompt layout
if [ -f "$HOME/.p10k.zsh" ] && ! cmp -s "$HERE/p10k.zsh" "$HOME/.p10k.zsh"; then
  cp "$HOME/.p10k.zsh" "$HOME/.p10k.zsh.bak.$(date +%Y%m%d-%H%M%S)"
fi
cp "$HERE/p10k.zsh" "$HOME/.p10k.zsh"
say "Prompt layout → ~/.p10k.zsh"

# 5. ~/.zshrc: managed block between markers, rest of the file untouched
BEGIN="# >>> zsh-setup (managed) >>>"
END="# <<< zsh-setup (managed) <<<"
RC="$HOME/.zshrc"
touch "$RC"
cp "$RC" "$RC.bak.$(date +%Y%m%d-%H%M%S)"
awk -v b="$BEGIN" -v e="$END" '$0 == b {skip = 1} !skip {print} $0 == e {skip = 0}' "$RC" > "$RC.tmp"
{
  echo "$BEGIN"
  cat <<'ZRC'
# Instant prompt: keep near the top.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"
plugins=(git zsh-autosuggestions zsh-syntax-highlighting fast-syntax-highlighting zsh-autocomplete)
source "$ZSH/oh-my-zsh.sh"
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh
ZRC
  echo "$END"
  cat "$RC.tmp"
} > "$RC"
rm -f "$RC.tmp"
say "$RC updated (backup saved next to it)"

# 6. Font for icons
if [ "$DO_FONT" = 1 ]; then
  if [ "$(uname -s)" = Darwin ]; then FONTS="$HOME/Library/Fonts"; else FONTS="$HOME/.local/share/fonts"; fi
  mkdir -p "$FONTS"
  base="https://github.com/romkatv/powerlevel10k-media/raw/master"
  for f in "MesloLGS NF Regular.ttf" "MesloLGS NF Bold.ttf" "MesloLGS NF Italic.ttf" "MesloLGS NF Bold Italic.ttf"; do
    [ -f "$FONTS/$f" ] || curl -fsSL -o "$FONTS/$f" "$base/${f// /%20}"
  done
  has fc-cache && fc-cache -f "$FONTS" >/dev/null 2>&1 || true
  say "Font MesloLGS NF installed — select it in your terminal settings"
fi

# 7. aliasx
if [ "$DO_ALIASX" = 1 ] && [ -x "$ROOT/install.sh" ]; then
  say "Installing aliasx"
  "$ROOT/install.sh" | sed 's/^/    /'
fi

# 8. Default shell
if [ "$DO_CHSH" = 1 ] && [ "$(basename "${SHELL:-}")" != zsh ]; then
  zsh_path="$(command -v zsh)"
  grep -qx "$zsh_path" /etc/shells 2>/dev/null || echo "$zsh_path" | $SUDO tee -a /etc/shells >/dev/null
  say "Making zsh your login shell (may ask for your password)"
  chsh -s "$zsh_path" || echo "    chsh failed; run: chsh -s $zsh_path"
fi

say "Done. Open a new terminal (or run: exec zsh)."
