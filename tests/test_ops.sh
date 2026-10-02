. "$ALIASX_ROOT/tests/helpers.sh"
stubs="$(mktemp -d)"; log="$stubs/calls.log"
for t in ssh terraform crontab; do
  printf '#!/bin/sh\necho "%s $*" >> "%s"\n' "$t" "$log" > "$stubs/$t"; chmod +x "$stubs/$t"
done
# kubectl stub: secret value is base64 of "s3cret"
printf '#!/bin/sh\necho "kubectl $*" >> "%s"\ncase "$*" in *jsonpath*data*) printf czNjcmV0 ;; esac\n' "$log" > "$stubs/kubectl"
chmod +x "$stubs/kubectl"
PATH="$stubs:$PATH"
. "$ALIASX_ROOT/aliasx.sh"

for f in retry every tunnel certexp certfile dnscheck logsize; do assert_function "$f"; done
for a in crons tfpo tfao kbad kimages kgall; do assert_alias "$a"; done
for f in ksecret kshell krun; do assert_function "$f"; done

# retry: succeeds on 3rd try
c="$stubs/count"; echo 0 > "$c"
retry 5 sh -c "n=\$(cat $c); n=\$((n+1)); echo \$n > $c; [ \$n -ge 3 ]" >/dev/null 2>&1
assert_eq "$?" "0" "retry eventually succeeds"
assert_eq "$(cat "$c")" "3" "retry stops after success"
# retry: gives up with command's failure
retry 2 false >/dev/null 2>&1; assert_eq "$?" "1" "retry gives up"
retry >/dev/null 2>&1; assert_eq "$?" "2" "retry usage"

# tunnel builds ssh -L
: > "$log"; tunnel 5433 db.internal:5432 user@bastion >/dev/null 2>&1
grep -q 'ssh -N -L 5433:db.internal:5432 user@bastion' "$log" || { echo "  tunnel args:"; cat "$log"; _failures=$((_failures + 1)); }

# ksecret decodes
assert_eq "$(ksecret db-creds password)" "s3cret" "ksecret decode"

# certfile: days left on a fresh 365-day cert
tmp="$(mktemp -d)"; cd "$tmp" || exit 1
openssl req -x509 -newkey rsa:2048 -nodes -days 365 -subj /CN=t -keyout t.key -out t.crt 2>/dev/null
out="$(certfile t.crt)"
case "$out" in *"days left: 36"[45]*) ;; *) echo "  certfile: $out"; _failures=$((_failures + 1)) ;; esac
cd /; command rm -r "$tmp" "$stubs"
finish
