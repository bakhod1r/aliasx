. "$ALIASX_ROOT/tests/helpers.sh"
. "$ALIASX_ROOT/aliasx.sh"

assert_eq "$(aliasx version)" "$(cat "$ALIASX_ROOT/VERSION")" "aliasx version"
case "$(aliasx version)" in [0-9]*.[0-9]*.[0-9]*) ;; *) echo "  VERSION not semver"; _failures=$((_failures + 1)) ;; esac

# update: fast-forwards a clone and reports the new version
tmp="$(mktemp -d)"
git init -q -b main "$tmp/origin"
cp -R "$ALIASX_ROOT/aliasx.sh" "$ALIASX_ROOT/aliases" "$ALIASX_ROOT/optional" "$ALIASX_ROOT/VERSION" "$tmp/origin/"
echo 1.0.0 > "$tmp/origin/VERSION"
git -C "$tmp/origin" add -A && git -C "$tmp/origin" -c user.email=t@t -c user.name=t commit -qm v1
git clone -q "$tmp/origin" "$tmp/clone"
echo 1.1.0 > "$tmp/origin/VERSION"; git -C "$tmp/origin" -c user.email=t@t -c user.name=t commit -qam v1.1
out="$(ALIASX_ROOT="$tmp/clone" _aliasx_update)"
assert_eq "$out" "aliasx 1.0.0 → 1.1.0. Run: reload" "update message"
assert_eq "$(ALIASX_ROOT="$tmp/clone" _aliasx_update)" "aliasx 1.1.0 is up to date" "already current"
ALIASX_ROOT="$tmp" _aliasx_update >/dev/null 2>&1; assert_eq "$?" "1" "update outside git checkout"

# doctor prints the key facts
out="$(HOME="$tmp" aliasx doctor)"
for k in "aliasx " "shell " "profile " "conflicts:"; do
  case "$out" in *"$k"*) ;; *) echo "  doctor missing '$k'"; _failures=$((_failures + 1)) ;; esac
done
command rm -rf "$tmp"
finish
