# Networking and HTTP.

# == General
alias ping5='ping -c 5'  # ping 5 times
alias conns='lsof -nP -i'  # open network connections
alias hosts='cat /etc/hosts'  # show /etc/hosts
alias dns='cat /etc/resolv.conf'  # show DNS resolvers

# myip — public IP (api.ipify.org)
#   $ myip
#   203.0.113.42
myip() {
  if has curl; then curl -fsS https://api.ipify.org; echo
  else wget -qO- https://api.ipify.org; echo; fi
}

# lanip — local network IP
#   $ lanip
#   192.168.1.23
lanip() {
  if [ "$ALIASX_OS" = macos ]; then
    ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1
  else
    hostname -I 2>/dev/null | awk '{print $1}'
  fi
}

# == Ports
# ports [PORT] — listening TCP ports, or who listens on PORT
#   $ ports 3000
#   COMMAND  PID  USER  FD  TYPE  DEVICE  NODE NAME
#   node    4123  ali   23u IPv4  0x...   TCP *:3000 (LISTEN)
ports() {
  if [ "$#" -eq 0 ]; then lsof -nP -iTCP -sTCP:LISTEN
  else lsof -nP -iTCP:"$1" -sTCP:LISTEN; fi
}

# freeport PORT — kill what listens on PORT after y/N
#   $ freeport 3000
#   node    4123  ali   23u IPv4  TCP *:3000 (LISTEN)
#   Kill these processes? [y/N] y
freeport() {
  [ "$#" -eq 1 ] || { echo "Usage: freeport <port>" >&2; return 2; }
  _pids="$(lsof -tiTCP:"$1" -sTCP:LISTEN)"
  [ -n "$_pids" ] || { echo "Nothing listens on port $1."; unset _pids; return 0; }
  lsof -nP -iTCP:"$1" -sTCP:LISTEN
  printf 'Kill these processes? [y/N] '; read -r _a
  case "$_a" in y|Y|yes) echo "$_pids" | xargs kill ;; *) echo "Cancelled." ;; esac
  unset _pids _a
}

# == HTTP
alias curlh='curl --head'  # response headers only
alias curlv='curl --verbose'  # verbose curl
alias curlj='curl -H "Accept: application/json"'  # curl asking for JSON
