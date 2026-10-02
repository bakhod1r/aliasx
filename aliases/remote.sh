# Remote work: ssh and tmux.

if has ssh; then
  # == SSH
  alias sshkeys='ls -l ~/.ssh/*.pub'  # your public keys
  alias sshconf='${EDITOR:-vi} ~/.ssh/config'  # edit ssh config
  alias sshagent='ssh-add -l'  # keys loaded in agent

  # sshgen [NAME] — new ed25519 key at ~/.ssh/NAME (default id_ed25519)
  #   $ sshgen work
  #   Generating public/private ed25519 key pair.
  #   ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI... ali@laptop
  sshgen() {
    _k="$HOME/.ssh/${1:-id_ed25519}"
    [ -e "$_k" ] && { echo "sshgen: $_k already exists" >&2; unset _k; return 1; }
    ssh-keygen -t ed25519 -f "$_k" && cat "$_k.pub"
    unset _k
  }

  # sshcopy USER@HOST — install your public key on a server
  #   $ sshcopy deploy@203.0.113.10
  #   Number of key(s) added: 1
  sshcopy() {
    [ "$#" -ge 1 ] || { echo "Usage: sshcopy <user@host> [ssh-copy-id options]" >&2; return 2; }
    ssh-copy-id "$@"
  }
fi

if has tmux; then
  # == tmux
  alias tl='tmux ls'  # list sessions
  alias ta='tmux attach -t'  # attach to session
  alias tn='tmux new -s'  # new named session

  # tk SESSION — kill a tmux session after y/N
  #   $ tk old
  #   Kill tmux session 'old'? [y/N] y
  tk() {
    [ "$#" -eq 1 ] || { echo "Usage: tk <session>" >&2; return 2; }
    yesno "Kill tmux session '$1'?" && tmux kill-session -t "$1"
  }
fi
