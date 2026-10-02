# Shared assertions. Sourced by test files under bash or zsh.
_failures=0

assert_alias() {
  if ! alias "$1" >/dev/null 2>&1; then
    echo "  expected alias: $1"; _failures=$((_failures + 1))
  fi
}

refute_alias() {
  if alias "$1" >/dev/null 2>&1; then
    echo "  unexpected alias: $1"; _failures=$((_failures + 1))
  fi
}

assert_function() {
  if ! typeset -f "$1" >/dev/null 2>&1; then
    echo "  expected function: $1"; _failures=$((_failures + 1))
  fi
}

assert_eq() {
  if [ "$1" != "$2" ]; then
    echo "  $3: expected [$2] got [$1]"; _failures=$((_failures + 1))
  fi
}

# isolated_path — PATH with only basic tools, so docker/kubectl/... look missing
# even on CI runners that have them preinstalled.
isolated_path() {
  _ip="$(mktemp -d)"
  for _c in sh bash zsh awk sed grep sort uniq cat tr head tail cut wc date mktemp rm mkdir ls \
            basename dirname uname env touch cp mv chmod id find xargs printf tee; do
    _p="$(command -v "$_c" 2>/dev/null)" && case "$_p" in /*) ln -s "$_p" "$_ip/$_c" ;; esac
  done
  echo "$_ip"; unset _c _p _ip
}

finish() { [ "$_failures" -eq 0 ]; exit $?; }
