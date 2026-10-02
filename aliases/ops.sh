# DevOps: retries, tunnels, certificates, DNS, cron, logs.

# == Run control
# retry N CMD... — run CMD up to N times, waiting 1s, 2s, 4s... between tries
#   $ retry 3 curl -f localhost:8080/health
#   retry: try 1 failed, waiting 1s
#   ok
function retry {
  [ "$#" -ge 2 ] || { echo "Usage: retry <times> <command> [args]" >&2; return 2; }
  _n="$1"; _i=1; _w=1; shift
  while :; do
    "$@" && { unset _n _i _w; return 0; }
    _rc=$?
    [ "$_i" -ge "$_n" ] && { echo "retry: failed after $_n tries" >&2; unset _n _i _w; return "$_rc"; }
    echo "retry: try $_i failed, waiting ${_w}s" >&2
    sleep "$_w"; _i=$((_i + 1)); _w=$((_w * 2))
  done
}

# every SEC CMD... — run CMD every SEC seconds (watch without clearing)
#   $ every 5 kubectl get pods
#   ── 10:31:02
#   NAME                  READY   STATUS
#   api-7d9f8b-x2k4       1/1     Running
function every {
  [ "$#" -ge 2 ] || { echo "Usage: every <seconds> <command> [args]" >&2; return 2; }
  _s="$1"; shift
  while :; do echo "── $(date +%H:%M:%S)"; "$@"; sleep "$_s"; done
}

# == Remote
# tunnel LOCALPORT TARGET:PORT USER@JUMP — forward localhost:LOCALPORT through ssh
#   $ tunnel 5433 db.internal:5432 ali@bastion
#   localhost:5433 → db.internal:5432 via ali@bastion (Ctrl-C to stop)
function tunnel {
  [ "$#" -eq 3 ] || { echo "Usage: tunnel <local-port> <target:port> <user@jump-host>" >&2; return 2; }
  echo "localhost:$1 → $2 via $3 (Ctrl-C to stop)"
  ssh -N -L "$1:$2" "$3"
}

# == Certificates
function _aliasx_cert_report {
  openssl x509 -noout -subject -issuer -enddate | python3 -c '
import sys, ssl, time
for line in sys.stdin:
    line = line.strip(); print(line)
    if line.startswith("notAfter="):
        days = int((ssl.cert_time_to_seconds(line[9:]) - time.time()) // 86400)
        print("days left: %d%s" % (days, "  ← renew soon" if days < 21 else ""))'
}

# certexp HOST[:PORT] — certificate subject, issuer and days until expiry
#   $ certexp example.com
#   subject=CN=example.com
#   issuer=C=US, O=Let's Encrypt, CN=R11
#   notAfter=Dec 30 23:59:59 2026 GMT
#   days left: 89
function certexp {
  [ "$#" -eq 1 ] || { echo "Usage: certexp <host[:port]>" >&2; return 2; }
  _h="${1%%:*}"; _p="${1##*:}"; [ "$_h" = "$_p" ] && _p=443
  openssl s_client -connect "$_h:$_p" -servername "$_h" </dev/null 2>/dev/null | _aliasx_cert_report
  unset _h _p
}

# certfile FILE — same report for a local .crt/.pem file
#   $ certfile /etc/ssl/certs/site.crt
#   subject=CN=site.local
#   notAfter=Oct 20 10:00:00 2026 GMT
#   days left: 18  ← renew soon
function certfile {
  [ "$#" -eq 1 ] || { echo "Usage: certfile <file>" >&2; return 2; }
  _aliasx_cert_report < "$1"
}

# == DNS and sockets
# dnscheck NAME [TYPE] — compare answers from system, Cloudflare and Google DNS
#   $ dnscheck api.example.com
#   system    93.184.215.14
#   1.1.1.1   93.184.215.14
#   8.8.8.8   93.184.215.14
function dnscheck {
  [ "$#" -ge 1 ] || { echo "Usage: dnscheck <name> [type]" >&2; return 2; }
  for _r in "" 1.1.1.1 8.8.8.8; do
    printf '%-9s %s\n' "${_r:-system}" "$(dig +short ${_r:+@$_r} "$1" "${2:-A}" | tr '\n' ' ')"
  done
  unset _r
}

if [ "$ALIASX_OS" = linux ]; then
  alias sockets='ss -tulpn'  # listening sockets with processes
fi

# == Cron and logs
has crontab && alias crons='crontab -l'  # your cron jobs

# logsize [DIR] — biggest log files (default /var/log)
#   $ logsize
#   812M	/var/log/journal/system.journal
#   120M	/var/log/nginx/access.log
function logsize { find "${1:-/var/log}" -type f -exec du -k {} + 2>/dev/null | _aliasx_topsize 15; }
