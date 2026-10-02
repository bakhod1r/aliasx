# shellcheck disable=SC2016  # stubs and piped answers are intentional
. "$ALIASX_ROOT/tests/helpers.sh"
stubs="$(mktemp -d)"; log="$stubs/calls.log"
# curl stub: log args, answer with JSON
printf '#!/bin/sh\nfor a in "$@"; do printf "[%%s]" "$a"; done >> "%s"; echo >> "%s"\necho "{\\"ok\\":true}"\n' "$log" "$log" > "$stubs/curl"
chmod +x "$stubs/curl"
PATH="$stubs:$PATH"
. "$ALIASX_ROOT/aliasx.sh"

for f in hget hpost hput hpatch hdelete timing jwt waitport watchurl hexkey selfcert; do assert_function "$f"; done
has jq && assert_alias jl

# hget sends Accept json, prints body
out="$(hget http://x/api)"
case "$out" in *ok*) ;; *) echo "  hget body: $out"; _failures=$((_failures + 1)) ;; esac
grep -q '\[Accept: application/json\]' "$log" || { echo "  hget missing Accept"; _failures=$((_failures + 1)); }

# hpost sends method, content type and body
: > "$log"; hpost http://x/users '{"name":"a b"}' >/dev/null
grep -q '\[-X\]\[POST\]' "$log" || { echo "  hpost method"; _failures=$((_failures + 1)); }
grep -q '\[Content-Type: application/json\]' "$log" || { echo "  hpost content-type"; _failures=$((_failures + 1)); }
grep -q '\[{"name":"a b"}\]' "$log" || { echo "  hpost body"; _failures=$((_failures + 1)); }

# hdelete asks first
: > "$log"; echo n | hdelete http://x/users/1 >/dev/null 2>&1
[ -s "$log" ] && { echo "  hdelete ran without y"; _failures=$((_failures + 1)); }
echo y | hdelete http://x/users/1 >/dev/null 2>&1
grep -q '\[-X\]\[DELETE\]' "$log" || { echo "  hdelete after y"; _failures=$((_failures + 1)); }

# jwt decodes header and payload
tok="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjMiLCJuYW1lIjoiQWxpIn0.sig"
out="$(jwt "$tok")"
case "$out" in *'"alg": "HS256"'*'"sub": "123"'*'"name": "Ali"'*) ;; *) echo "  jwt: $out"; _failures=$((_failures + 1)) ;; esac
jwt "not-a-token" >/dev/null 2>&1; assert_eq "$?" "1" "jwt bad token"

# hexkey length
assert_eq "$(hexkey | tr -d '\n' | wc -c | tr -d ' ')" "64" "hexkey default 32 bytes"
assert_eq "$(hexkey 16 | tr -d '\n' | wc -c | tr -d ' ')" "32" "hexkey 16 bytes"

# waitport: closed port times out with 1
waitport 127.0.0.1 1 1 >/dev/null 2>&1; assert_eq "$?" "1" "waitport timeout"

# selfcert writes cert and key
tmp="$(mktemp -d)"; cd "$tmp" || exit 1
selfcert dev.local >/dev/null 2>&1
if [ ! -f dev.local.crt ] || [ ! -f dev.local.key ]; then echo "  selfcert files"; _failures=$((_failures + 1)); fi
openssl x509 -in dev.local.crt -noout -subject 2>/dev/null | grep -q dev.local || { echo "  selfcert subject"; _failures=$((_failures + 1)); }
cd /; command rm -r "$tmp" "$stubs"
finish
