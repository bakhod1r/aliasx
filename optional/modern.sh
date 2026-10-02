# Opt-in: replace standard commands with modern tools.
# Enable: ALIASX_ENABLE="modern"

# == Replacements
if has eza; then
  alias ls='eza --group-directories-first'  # list with colors, folders marked
  alias ll='eza --long --group-directories-first --git'  # long list, folders first
  alias la='eza --long --all --group-directories-first --git'  # long list incl. hidden
  alias l='eza --group-directories-first'  # compact list, folders first
  alias etree='eza --tree --level=2'  # tree, 2 levels
fi
if has bat; then
  alias cat='bat --paging=never'  # bat without pager
elif has batcat; then
  alias cat='batcat --paging=never'  # bat without pager
fi
if has btop; then
  alias top='btop'  # modern top
elif has htop; then
  alias top='htop'  # modern top
fi
has zoxide && eval "$(zoxide init "$([ -n "${ZSH_VERSION:-}" ] && echo zsh || echo bash)")"
