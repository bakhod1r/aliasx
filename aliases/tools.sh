# Modern CLI tools that add new names only (never replace standard commands).
# Replacing ls/cat/top lives in optional/modern.sh.

# == TUI helpers
has lazygit && alias lg='lazygit'  # lazygit
has lazydocker && alias ldk='lazydocker'  # lazydocker

# == Search
if has rg; then
  alias rgf='rg --files'  # list files ripgrep sees
  alias rgh='rg --hidden --glob "!.git/*"'  # search incl. hidden files
fi
! has fd && has fdfind && alias fd='fdfind'  # fd (Debian name fdfind)
! has bat && has batcat && alias bat='batcat'  # bat (Debian name batcat)
