# Sysadmin: users, logins, services, disk hogs, kernel messages.

# == Users and logins
alias logins='last -n 20'  # last 20 logins
alias reboots='last reboot | head'  # reboot history

# userinfo USER — id, groups, shell, home and last login
#   $ userinfo deploy
#   uid=1001(deploy) gid=1001(deploy) groups=1001(deploy),27(sudo),998(docker)
#   home=/home/deploy shell=/bin/bash
#   deploy   pts/0   10.0.0.5   Thu Oct  1 09:12   still logged in
userinfo() {
  [ "$#" -eq 1 ] || { echo "Usage: userinfo <user>" >&2; return 2; }
  id "$1" 2>/dev/null || { echo "userinfo: no user '$1'" >&2; return 1; }
  if [ "$ALIASX_OS" = linux ]; then getent passwd "$1" | awk -F: '{print "home=" $6 " shell=" $7}'
  else dscl . -read "/Users/$1" NFSHomeDirectory UserShell 2>/dev/null | tr '\n' ' '; echo; fi
  last -n 1 "$1" 2>/dev/null | head -1
}

# failedlogins — recent failed SSH logins
#   $ failedlogins
#   Oct 02 03:14:07 web1 sshd[9120]: Failed password for root from 203.0.113.9 port 51022 ssh2
#   Oct 02 03:14:11 web1 sshd[9120]: Failed password for root from 203.0.113.9 port 51022 ssh2
failedlogins() {
  if has journalctl; then journalctl -u ssh -u sshd --since "24 hours ago" --no-pager 2>/dev/null | grep -i "failed password"
  elif [ -f /var/log/auth.log ]; then grep -i "failed password" /var/log/auth.log | tail -40
  else log show --last 24h --predicate 'process == "sshd"' 2>/dev/null | grep -i fail; fi
}

if [ "$ALIASX_OS" = linux ]; then
  alias humans="awk -F: '\$3>=1000 && \$3<65534 {print \$1}' /etc/passwd"  # real user accounts
fi

# == Services (systemd)
if has systemctl; then
  alias enabled='systemctl list-unit-files --state=enabled'  # services that start at boot

  # svc NAME — status and last 20 log lines of a service
  #   $ svc nginx
  #   ● nginx.service - A high performance web server
  #        Active: active (running) since Thu 2026-10-01 08:00:12 UTC; 1 day ago
  #      Main PID: 812 (nginx)
  svc() {
    [ "$#" -eq 1 ] || { echo "Usage: svc <service>" >&2; return 2; }
    systemctl status "$1" --no-pager -n 20
  }

  # svcr NAME — restart a service after y/N
  #   $ svcr nginx
  #   Restart nginx? [y/N] y
  svcr() {
    [ "$#" -eq 1 ] || { echo "Usage: svcr <service>" >&2; return 2; }
    yesno "Restart $1?" && sudo systemctl restart "$1"
  }

  # svcstop NAME — stop a service after y/N
  #   $ svcstop nginx
  #   Stop nginx? [y/N] n
  #   Cancelled.
  svcstop() {
    [ "$#" -eq 1 ] || { echo "Usage: svcstop <service>" >&2; return 2; }
    yesno "Stop $1?" && sudo systemctl stop "$1"
  }
fi

# == Disk
alias deleted='lsof +L1'  # deleted files still holding disk space

# bigfiles [DIR] [SIZE] — files bigger than SIZE (default . 100M)
#   $ bigfiles /var 500M
#   2.1G	/var/lib/docker/overlay2/3f1c.../layer.tar
#   812M	/var/log/journal/system@0001.journal
bigfiles() {
  find "${1:-.}" -xdev -type f -size +"${2:-100M}" -exec du -h {} + 2>/dev/null | sort -rh | head -20
}

# == Kernel
if [ "$ALIASX_OS" = linux ]; then
  alias kmsg='sudo dmesg -T | tail -40'  # last kernel messages
  alias oom='journalctl -k | grep -i "out of memory"'  # out-of-memory kills
  alias timesync='timedatectl'  # clock and NTP status
fi
