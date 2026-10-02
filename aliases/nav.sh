# Navigation and listing.

# == Moving around
alias ..='cd ..'  # up one directory
alias ...='cd ../..'  # up two directories
alias ....='cd ../../..'  # up three directories
alias .....='cd ../../../..'  # up four directories
alias -- -='cd -'  # previous directory
alias home='cd "$HOME"'  # go to home directory

# mkcd DIR — create directory and enter it
#   $ mkcd projects/demo
#   (created and now inside projects/demo)
mkcd() {
  [ "$#" -eq 1 ] || { echo "Usage: mkcd <directory>" >&2; return 2; }
  mkdir -p -- "$1" && cd -- "$1"
}

# up [N] — go up N directories (default 1)
#   $ up 2
#   (moved two folders up)
up() {
  case "${1:-1}" in ''|*[!0-9]*) echo "Usage: up [number]" >&2; return 2 ;; esac
  _n="${1:-1}" _p=""
  while [ "$_n" -gt 0 ]; do _p="../$_p"; _n=$((_n - 1)); done
  cd -- "${_p:-.}"
  unset _n _p
}

# croot — go to the root of the current git repository
#   $ croot
#   (now at the repository root)
croot() {
  _r="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "Not inside a git repository" >&2; return 1; }
  cd -- "$_r"; unset _r
}

# == Listing
# Folders are marked with / and listed first. On macOS folders-first needs
# GNU ls (brew install coreutils provides gls); without it only the / marker.
if command ls --group-directories-first / >/dev/null 2>&1; then
  _aliasx_ls='ls --color=auto -F --group-directories-first'
elif has gls; then
  _aliasx_ls='gls --color=auto -F --group-directories-first'
else
  _aliasx_ls='ls -G -F'
fi
alias ls="$_aliasx_ls"  # list, folders marked with /
alias ll="$_aliasx_ls -lh"  # long list
alias la="$_aliasx_ls -lAh"  # long list incl. hidden
alias l="$_aliasx_ls -C"  # compact list
unset _aliasx_ls
alias ldirs='ls -d -- */'  # list only folders
alias lfiles='ls -p | grep -v /'  # list only files
alias tree2='tree -L 2'  # tree, 2 levels
alias tree3='tree -L 3'  # tree, 3 levels
