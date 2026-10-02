#!/usr/bin/env bash
# Runs every tests/test_*.sh under bash and zsh. Exit non-zero on any failure.
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fail=0
for shell in bash zsh; do
  command -v "$shell" >/dev/null 2>&1 || { echo "skip: $shell not installed"; continue; }
  for t in "$ROOT"/tests/test_*.sh; do
    if ALIASX_ROOT="$ROOT" "$shell" "$t"; then
      echo "PASS [$shell] $(basename "$t")"
    else
      echo "FAIL [$shell] $(basename "$t")"
      fail=1
    fi
  done
done
exit $fail
