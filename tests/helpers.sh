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

finish() { [ "$_failures" -eq 0 ]; exit $?; }
