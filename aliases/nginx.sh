# nginx: test, reload, logs. Config is always tested before reload/restart.
has nginx || return 0

if [ "$ALIASX_OS" = macos ]; then _aliasx_ngsudo=''; else _aliasx_ngsudo='sudo '; fi

# Run as root on Linux, as yourself on macOS (Homebrew nginx).
function _aliasx_ngrun { if [ "$ALIASX_OS" = macos ]; then "$@"; else sudo "$@"; fi; }

# == Config
alias ngt="${_aliasx_ngsudo}nginx -t"  # test config
alias ngconf="${_aliasx_ngsudo}nginx -T"  # print full loaded config
alias ngv='nginx -V'  # version and build options
alias ngsites='ls -l /etc/nginx/sites-enabled /etc/nginx/conf.d 2>/dev/null'  # enabled sites

# ngr — test config, then reload if OK
#   $ ngr
#   nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
#   nginx: configuration file /etc/nginx/nginx.conf test is successful
function ngr {
  _aliasx_ng_test || return
  if has systemctl; then sudo systemctl reload nginx; else _aliasx_ngrun nginx -s reload; fi
}

# ngrestart — test config, then restart if OK
#   $ ngrestart
#   nginx: configuration file /etc/nginx/nginx.conf test is successful
function ngrestart {
  _aliasx_ng_test || return
  if has systemctl; then sudo systemctl restart nginx
  elif has brew; then brew services restart nginx
  else _aliasx_ngrun nginx -s stop && _aliasx_ngrun nginx; fi
}

# ngs — service status
#   $ ngs
#   ● nginx.service - A high performance web server
#        Active: active (running)
function ngs {
  if has systemctl; then systemctl status nginx --no-pager
  elif has brew; then brew services info nginx
  else pgrep -l nginx; fi
}

function _aliasx_ng_test { _aliasx_ngrun nginx -t || { echo "nginx: config has errors, nothing reloaded" >&2; return 1; }; }

# == Logs
# nge — follow error log
#   $ nge
#   2026/10/02 10:31:07 [error] 812#812: *41 connect() failed (111: Connection refused) while connecting to upstream
function nge { _aliasx_ng_log error; }

# nga — follow access log
#   $ nga
#   203.0.113.9 - - [02/Oct/2026:10:31:07 +0000] "GET /api/users HTTP/1.1" 200 512
function nga { _aliasx_ng_log access; }

function _aliasx_ng_log {
  for _d in /var/log/nginx /opt/homebrew/var/log/nginx /usr/local/var/log/nginx; do
    [ -f "$_d/$1.log" ] && { _aliasx_ngrun tail -f "$_d/$1.log"; unset _d; return; }
  done
  unset _d; echo "nginx $1.log not found" >&2; return 1
}
