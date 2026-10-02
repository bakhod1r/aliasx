# System: processes, services, packages, macOS.

# == Processes
alias kernel='uname -a'  # kernel and OS info
alias load='uptime'  # uptime and load
if [ "$ALIASX_OS" = macos ]; then
  alias mem='vm_stat'  # memory usage
  alias psmem='ps aux | sort -nrk 4 | head -11'  # top 10 by memory
  alias pscpu='ps aux | sort -nrk 3 | head -11'  # top 10 by CPU
else
  alias mem='free -h'  # memory usage
  alias psmem='ps aux --sort=-%mem | head -11'  # top 10 by memory
  alias pscpu='ps aux --sort=-%cpu | head -11'  # top 10 by CPU
fi

# please — rerun the previous command with sudo
alias please='eval "sudo $(fc -ln -1)"'  # rerun last command with sudo

# psgrep PATTERN — find processes by name
#   $ psgrep nginx
#   root   812  0.0  0.1  nginx: master process
#   www    813  0.0  0.2  nginx: worker process
function psgrep {
  [ "$#" -ge 1 ] || { echo "Usage: psgrep <pattern>" >&2; return 2; }
  ps aux | grep -i -- "$*" | grep -v grep
}

# == Linux hardware
if [ "$ALIASX_OS" = linux ]; then
  alias disks='lsblk -f'  # block devices and filesystems
  alias mounts='findmnt'  # mounted filesystems
fi
has nvidia-smi && alias gpuinfo='nvidia-smi'  # NVIDIA GPU status

# == systemd and logs
if has systemctl; then
  alias sc='systemctl'  # systemctl
  alias scu='systemctl --user'  # systemctl for user
  alias scfailed='systemctl --failed'  # failed units
  alias jc='journalctl'  # journalctl
  alias jcf='journalctl --follow'  # follow journal
  alias jcxe='journalctl -xe'  # recent journal with explanations
  alias jcerr='journalctl -p err..alert -b'  # errors since boot

  # svclogs SERVICE [OPTS] — journal for one service
  #   $ svclogs nginx -n 5
  #   Oct 02 10:31:07 web1 nginx[812]: started
  function svclogs {
    [ "$#" -ge 1 ] || { echo "Usage: svclogs <service> [journalctl options]" >&2; return 2; }
    _s="$1"; shift; journalctl -u "$_s" "$@"; unset _s
  }
fi

# == Firewall (ufw)
if has ufw; then
  alias ufws='sudo ufw status verbose'  # firewall rules
  alias ufwa='sudo ufw allow'  # allow port or service
  alias ufwd='sudo ufw deny'  # deny port or service
fi

# == Packages
# No -y: upgrades stay visible and confirmed.
if has apt; then
  alias aptup='sudo apt update && sudo apt upgrade'  # update and upgrade packages
  alias apti='sudo apt install'  # install package
  alias aptr='sudo apt remove'  # remove package
  alias apts='apt search'  # search packages
  alias aptclean='sudo apt autoremove'  # remove unused packages
fi
if has dnf; then
  alias dnfup='sudo dnf upgrade --refresh'  # upgrade packages
  alias dnfi='sudo dnf install'  # install package
  alias dnfr='sudo dnf remove'  # remove package
  alias dnfs='dnf search'  # search packages
fi
if has pacman; then
  alias pacup='sudo pacman -Syu'  # sync and upgrade packages
  alias paci='sudo pacman -S'  # install package
  alias pacr='sudo pacman -Rns'  # remove package and deps
  alias pacs='pacman -Ss'  # search packages
fi
if has apk; then
  alias apkup='sudo apk update && sudo apk upgrade'  # update and upgrade packages
  alias apki='sudo apk add'  # install package
  alias apkr='sudo apk del'  # remove package
fi
if has brew; then
  alias brewup='brew update && brew upgrade'  # update and upgrade formulae
  alias brewi='brew install'  # install formula
  alias brewr='brew uninstall'  # uninstall formula
  alias brews='brew search'  # search formulae
  alias brewclean='brew cleanup'  # remove old versions
fi

# == Power (Linux)
if has systemctl; then
  # sys-reboot — reboot machine after y/N
  #   $ sys-reboot
  #   Reboot web1 now? [y/N] n
  #   Cancelled.
  function sys-reboot { yesno "Reboot $(hostname) now?" && sudo systemctl reboot; }

  # sys-poweroff — power off machine after y/N
  #   $ sys-poweroff
  #   Power off web1 now? [y/N] n
  #   Cancelled.
  function sys-poweroff { yesno "Power off $(hostname) now?" && sudo systemctl poweroff; }

  # sys-suspend — suspend machine after y/N
  #   $ sys-suspend
  #   Suspend laptop now? [y/N] y
  function sys-suspend { yesno "Suspend $(hostname) now?" && sudo systemctl suspend; }
fi

# == macOS
if [ "$ALIASX_OS" = macos ]; then
  alias flushdns='sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder'  # flush DNS cache

  alias showfiles='defaults write com.apple.finder AppleShowAllFiles -bool true; killall Finder'  # show hidden files in Finder
  alias hidefiles='defaults write com.apple.finder AppleShowAllFiles -bool false; killall Finder'  # hide hidden files in Finder
fi

if [ "$ALIASX_OS" = macos ]; then
  # sleepnow — put the Mac to sleep after y/N
  #   $ sleepnow
  #   Sleep now? [y/N] y
  function sleepnow { yesno "Sleep now?" && pmset sleepnow; }
fi

# clipcopy — stdin to clipboard (pbcopy, wl-copy or xclip)
#   $ cat id_ed25519.pub | clipcopy
#   (public key copied to clipboard)
function clipcopy {
  if has pbcopy; then pbcopy
  elif has wl-copy; then wl-copy
  elif has xclip; then xclip -selection clipboard
  else echo "clipcopy: install xclip or wl-clipboard" >&2; return 1; fi
}

# clippaste — clipboard to stdout
#   $ clippaste > note.txt
#   (clipboard saved to note.txt)
function clippaste {
  if has pbpaste; then pbpaste
  elif has wl-paste; then wl-paste
  elif has xclip; then xclip -selection clipboard -o
  else echo "clippaste: install xclip or wl-clipboard" >&2; return 1; fi
}
