. "$ALIASX_ROOT/tests/helpers.sh"
cd "$ALIASX_ROOT" || exit 1

# Every file parses in bash and zsh.
for f in aliasx.sh aliases/*.sh optional/*.sh; do
  bash -n "$f" 2>/dev/null || { echo "  bash parse: $f"; _failures=$((_failures + 1)); }
  zsh -n "$f" 2>/dev/null  || { echo "  zsh parse: $f"; _failures=$((_failures + 1)); }
done

# No alias defined in two different places (OS branches inside one file are fine).
dups="$(for f in aliases/*.sh optional/*.sh; do
  sed -n "s/^[[:space:]]*alias \(-- \)\{0,1\}\([^=]*\)=.*/\2/p" "$f" | sort -u | sed "s|\$| $f|"
done | awk '{print $1}' | sort | uniq -d | grep -v -x -e ls -e ll -e la -e l)"
assert_eq "$dups" "" "aliases defined in more than one module"

# Default modules never call sudo implicitly except package and power commands.
bad="$(grep -n 'sudo' aliases/*.sh | grep -v -e 'aliases/system.sh' -e 'aliases/nginx.sh' -e 'aliases/admin.sh' )"
assert_eq "$bad" "" "unexpected sudo"

# No destructive one-liners in default modules.
bad="$(grep -n -E 'system prune|prune -a|rm -rf|delete all|destroy|reset --hard' aliases/*.sh | grep -v -e 'allow-destructive' -e ':[[:space:]]*#')"
assert_eq "$bad" "" "destructive command in default module"

# Every alias carries a description comment (used by hints and docs).
bad="$(grep -n -E "^[^#]*alias [^=]+=[\x27\"]" aliases/*.sh optional/*.sh | grep -v -E "[\x27\"][[:space:]]+# [^ ]")"
assert_eq "$bad" "" "alias without # description"

# An alias must be shorter than what it runs; otherwise just type the command.
long="$(awk '
  /^[[:space:]]*#/ { next }
  /alias (-- )?[^ =]+=[\x27"]/ {
    s = substr($0, index($0, "alias ") + 6); if (substr(s, 1, 3) == "-- ") s = substr(s, 4)
    e = index(s, "="); n = substr(s, 1, e - 1); q = substr(s, e + 1, 1); v = substr(s, e + 2)
    v = substr(v, 1, index(v, q) - 1)
    if (length(n) >= length(v)) print n
  }' aliases/*.sh optional/*.sh)"
assert_eq "$long" "" "alias not shorter than its command"

finish
