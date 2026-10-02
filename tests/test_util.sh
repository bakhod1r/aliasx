. "$ALIASX_ROOT/tests/helpers.sh"
. "$ALIASX_ROOT/aliasx.sh"
tmp="$(mktemp -d)"; cd "$tmp" || exit 1
real="$(pwd -P)"

for a in cx tailf e envg please; do assert_alias "$a"; done
for f in cl tmpd ftext tgz zipd dl newest perms genpass newuuid epoch fromepoch b64 b64d urlenc urldec httpcode digs topcmds sysinfo pk; do assert_function "$f"; done

# genpass length, default 20
assert_eq "$(genpass 12 | tr -d '\n' | wc -c | tr -d ' ')" "12" "genpass 12"
assert_eq "$(genpass | tr -d '\n' | wc -c | tr -d ' ')" "20" "genpass default"

# epoch / fromepoch (UTC)
case "$(epoch)" in ''|*[!0-9]*) echo "  epoch not numeric"; _failures=$((_failures + 1)) ;; esac
assert_eq "$(fromepoch 0)" "1970-01-01 00:00:00 UTC" "fromepoch 0"

# base64 and url round trips
assert_eq "$(b64 'hello world' | b64d)" "hello world" "b64 round trip"
assert_eq "$(urlenc 'a b&c/d')" "a%20b%26c%2Fd" "urlenc"
assert_eq "$(urldec 'a%20b%26c%2Fd')" "a b&c/d" "urldec"

# newuuid shape
case "$(newuuid)" in ????????-????-????-????-????????????) ;; *) echo "  newuuid shape"; _failures=$((_failures + 1)) ;; esac

# tgz + extract round trip
mkdir src && echo hi > src/f && tgz src >/dev/null
[ -f src.tar.gz ] || { echo "  tgz missing"; _failures=$((_failures + 1)); }
mkdir out && cd out && extract ../src.tar.gz && assert_eq "$(cat src/f)" "hi" "tgz content" && cd ..

# cl enters dir
cl src >/dev/null; assert_eq "$(pwd -P)" "$real/src" "cl enters"; cd "$real"

# perms
echo x > p; chmod 640 p; assert_eq "$(perms p)" "640 p" "perms"

# newest: last modified first
echo 1 > old; sleep 1; echo 2 > fresh
assert_eq "$(newest 1)" "fresh" "newest 1"

# ftext finds text, skips .git
mkdir -p .git && echo needle > .git/x && echo needle > found.txt
assert_eq "$(ftext needle)" "./found.txt:1:needle" "ftext"

# tmpd creates and enters a temp dir
before="$(pwd -P)"; tmpd >/dev/null
[ "$(pwd -P)" != "$before" ] && [ -d "$(pwd -P)" ] || { echo "  tmpd"; _failures=$((_failures + 1)); }
cd "$real"

# usage errors
pk >/dev/null 2>&1; assert_eq "$?" "2" "pk without args"
ftext >/dev/null 2>&1; assert_eq "$?" "2" "ftext without args"

cd /; command rm -r "$tmp"
finish
