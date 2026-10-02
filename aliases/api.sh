# Backend and API work: HTTP calls, timing, JWT, ports, keys, certs.

# == HTTP calls
# Responses are pretty-printed with jq when they are JSON.
function _aliasx_http {
  _m="$1"; _u="$2"; shift 2
  if [ "$#" -gt 0 ] && [ "${1#-}" = "$1" ]; then
    _b="$(curl -sS -X "$_m" -H 'Accept: application/json' -H 'Content-Type: application/json' --data "$1" "$_u")"
  else
    _b="$(curl -sS -X "$_m" -H 'Accept: application/json' "$_u" "$@")"
  fi
  if has jq && printf '%s' "$_b" | jq . >/dev/null 2>&1; then printf '%s' "$_b" | jq .; else printf '%s\n' "$_b"; fi
  unset _m _u _b
}

# hget URL [curl options] — GET, JSON pretty-printed
#   $ hget localhost:8080/users/1
#   {
#     "id": 1,
#     "name": "Ali"
#   }
function hget {
  [ "$#" -ge 1 ] || { echo "Usage: hget <url> [curl options]" >&2; return 2; }
  _u="$1"; shift; _aliasx_http GET "$_u" "$@"; unset _u
}

# hpost URL JSON — POST JSON body (use @file.json for a file)
#   $ hpost localhost:8080/users '{"name":"Vali"}'
#   {
#     "id": 2,
#     "name": "Vali"
#   }
function hpost {
  [ "$#" -ge 2 ] || { echo "Usage: hpost <url> <json|@file>" >&2; return 2; }
  _aliasx_http POST "$1" "$2"
}

# hput URL JSON — PUT JSON body
#   $ hput localhost:8080/users/2 '{"name":"Vali B"}'
#   {
#     "id": 2,
#     "name": "Vali B"
#   }
function hput {
  [ "$#" -ge 2 ] || { echo "Usage: hput <url> <json|@file>" >&2; return 2; }
  _aliasx_http PUT "$1" "$2"
}

# hpatch URL JSON — PATCH JSON body
#   $ hpatch localhost:8080/users/2 '{"active":false}'
#   {
#     "id": 2,
#     "active": false
#   }
function hpatch {
  [ "$#" -ge 2 ] || { echo "Usage: hpatch <url> <json|@file>" >&2; return 2; }
  _aliasx_http PATCH "$1" "$2"
}

# hdelete URL — DELETE after y/N
#   $ hdelete localhost:8080/users/2
#   DELETE localhost:8080/users/2 ? [y/N] y
function hdelete {
  [ "$#" -ge 1 ] || { echo "Usage: hdelete <url>" >&2; return 2; }
  yesno "DELETE $1 ?" && _aliasx_http DELETE "$1"
}

# timing URL — DNS, connect, TLS, first byte and total time
#   $ timing https://example.com
#   status:  200
#   dns:     0.012s
#   connect: 0.045s
#   tls:     0.110s
#   first:   0.230s
#   total:   0.241s
#   size:    1256 bytes
function timing {
  [ "$#" -ge 1 ] || { echo "Usage: timing <url>" >&2; return 2; }
  curl -sS -o /dev/null -w 'status:  %{http_code}\ndns:     %{time_namelookup}s\nconnect: %{time_connect}s\ntls:     %{time_appconnect}s\nfirst:   %{time_starttransfer}s\ntotal:   %{time_total}s\nsize:    %{size_download} bytes\n' "$@"
}

# watchurl URL [SEC] — print status code every SEC seconds (default 2)
#   $ watchurl localhost:8080/health
#   10:31:02  200 0.004s
#   10:31:04  200 0.003s
#   10:31:06  502 0.001s
function watchurl {
  [ "$#" -ge 1 ] || { echo "Usage: watchurl <url> [seconds]" >&2; return 2; }
  while :; do
    printf '%s  %s\n' "$(date +%H:%M:%S)" "$(curl -s -o /dev/null -w '%{http_code} %{time_total}s' "$1")"
    sleep "${2:-2}"
  done
}

# == Tokens and keys
# jwt TOKEN — decode JWT header and payload (no signature check)
#   $ jwt eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxMjMifQ.sig
#   {
#     "alg": "HS256"
#   }
#   {
#     "sub": "123"
#   }
function jwt {
  [ "$#" -eq 1 ] || { echo "Usage: jwt <token>" >&2; return 2; }
  python3 - "$1" <<'PY'
import base64, json, sys
parts = sys.argv[1].split(".")
if len(parts) < 2:
    sys.exit("jwt: not a token")
try:
    for p in parts[:2]:
        print(json.dumps(json.loads(base64.urlsafe_b64decode(p + "=" * (-len(p) % 4))), indent=2))
except Exception:
    sys.exit("jwt: cannot decode")
PY
}

# hexkey [BYTES] — random hex secret (default 32 bytes)
#   $ hexkey 16
#   9f2c4e1a7b3d8c05e6f1a2b3c4d5e6f7
function hexkey { openssl rand -hex "${1:-32}"; }

# selfcert DOMAIN — self-signed cert DOMAIN.crt + DOMAIN.key for local dev (1 year)
#   $ selfcert dev.local
#   dev.local.crt dev.local.key
function selfcert {
  [ "$#" -eq 1 ] || { echo "Usage: selfcert <domain>" >&2; return 2; }
  openssl req -x509 -newkey rsa:2048 -nodes -days 365 -subj "/CN=$1" \
    -keyout "$1.key" -out "$1.crt" 2>/dev/null && echo "$1.crt $1.key"
}

# == Services
# waitport HOST PORT [SEC] — wait until PORT accepts connections (default 30s)
#   $ waitport localhost 5432
#   localhost:5432 is up
function waitport {
  [ "$#" -ge 2 ] || { echo "Usage: waitport <host> <port> [seconds]" >&2; return 2; }
  _i=0
  while [ "$_i" -lt "${3:-30}" ]; do
    if nc -z "$1" "$2" 2>/dev/null; then echo "$1:$2 is up"; unset _i; return 0; fi
    sleep 1; _i=$((_i + 1))
  done
  echo "$1:$2 not up after ${3:-30}s" >&2; unset _i; return 1
}

# == Logs
has jq && alias jl="jq -R 'fromjson? // .'"  # readable JSON log lines
