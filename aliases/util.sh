# Utilities: passwords, ids, time, encoding, quick checks.

# == Generate
# genpass [N] — random password, N chars (default 20)
#   $ genpass 16
#   q7K#m2Rx_9vT!pLz
genpass() { LC_ALL=C tr -dc 'A-Za-z0-9!@#%^_+=-' </dev/urandom | head -c "${1:-20}"; echo; }

# newuuid — random UUID (lowercase)
#   $ newuuid
#   3f1c9b2e-7a4d-4e8f-9c21-5b6a7d8e9f01
newuuid() {
  if has uuidgen; then uuidgen | tr 'A-Z' 'a-z'
  else cat /proc/sys/kernel/random/uuid; fi
}

# == Time
# epoch — current Unix timestamp
#   $ epoch
#   1790932262
epoch() { date +%s; }

# fromepoch TS — Unix timestamp to UTC date
#   $ fromepoch 0
#   1970-01-01 00:00:00 UTC
fromepoch() {
  [ "$#" -eq 1 ] || { echo "Usage: fromepoch <timestamp>" >&2; return 2; }
  date -u -d "@$1" '+%Y-%m-%d %H:%M:%S UTC' 2>/dev/null || date -u -r "$1" '+%Y-%m-%d %H:%M:%S UTC'
}

# == Encode
# b64 [TEXT] — base64 encode TEXT or stdin
#   $ b64 hello
#   aGVsbG8=
b64() { if [ "$#" -gt 0 ]; then printf '%s' "$*" | base64; else base64; fi; }

# b64d [TEXT] — base64 decode TEXT or stdin
#   $ b64d aGVsbG8=
#   hello
b64d() {
  if [ "$#" -gt 0 ]; then printf '%s' "$*" | base64 --decode; else base64 --decode; fi
  echo
}

# urlenc TEXT — percent-encode for URLs
#   $ urlenc 'a b&c'
#   a%20b%26c
urlenc() { python3 -c 'import sys,urllib.parse;print(urllib.parse.quote(sys.argv[1],safe=""))' "$*"; }

# urldec TEXT — decode percent-encoding
#   $ urldec a%20b%26c
#   a b&c
urldec() { python3 -c 'import sys,urllib.parse;print(urllib.parse.unquote(sys.argv[1]))' "$*"; }

# == Quick checks
# httpcode URL — HTTP status code only
#   $ httpcode https://example.com
#   200
httpcode() {
  [ "$#" -eq 1 ] || { echo "Usage: httpcode <url>" >&2; return 2; }
  curl -s -o /dev/null -w '%{http_code}\n' -- "$1"
}

# digs NAME — DNS answer only
#   $ digs example.com
#   93.184.215.14
digs() {
  [ "$#" -ge 1 ] || { echo "Usage: digs <name> [type]" >&2; return 2; }
  dig +short "$@"
}

# topcmds [N] — your most used commands (default 15)
#   $ topcmds 3
#     412 git
#     210 docker
#     155 cd
topcmds() { fc -l 1 | awk '{print $2}' | sort | uniq -c | sort -rn | head -n "${1:-15}"; }

# sysinfo — OS, CPU, memory, disk, uptime in one screen
#   $ sysinfo
#   OS:     Linux 6.8.0 x86_64
#   Host:   web1
#   CPU:    AMD EPYC 7763 (4 cores)
#   Memory: 3.1Gi used / 7.7Gi
#   Disk /: 21G used / 79G (27%)
#   Uptime: up 12 days
sysinfo() {
  echo "OS:     $(uname -sr) $(uname -m)"
  echo "Host:   $(hostname)"
  if [ "$ALIASX_OS" = macos ]; then
    echo "CPU:    $(sysctl -n machdep.cpu.brand_string) ($(sysctl -n hw.ncpu) cores)"
    echo "Memory: $(( $(sysctl -n hw.memsize) / 1073741824 )) GB"
  else
    echo "CPU:    $(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2 | sed 's/^ //') ($(nproc) cores)"
    echo "Memory: $(free -h | awk '/^Mem/ {print $3 " used / " $2}')"
  fi
  echo "Disk /: $(df -h / | awk 'NR==2 {print $3 " used / " $2 " (" $5 ")"}')"
  echo "Uptime:$(uptime | sed 's/.*up/ up/; s/,  *[0-9]* user.*//')"
}

# pk NAME — kill processes by name after y/N
#   $ pk node
#   4123 node server.js
#   Kill these processes? [y/N] n
#   Cancelled.
pk() {
  [ "$#" -eq 1 ] || { echo "Usage: pk <name>" >&2; return 2; }
  pgrep -fl -- "$1" || { echo "No process matches '$1'."; return 0; }
  printf 'Kill these processes? [y/N] '; read -r _a
  case "$_a" in y|Y|yes) pkill -f -- "$1" ;; *) echo "Cancelled." ;; esac
  unset _a
}
