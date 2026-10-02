#!/usr/bin/env bash
# Runs every tests/test_*.sh under bash and zsh. Exit non-zero on any failure.
# Each test gets stdin from /dev/null and a time limit (ALIASX_TEST_TIMEOUT, default 120s).
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LIMIT="${ALIASX_TEST_TIMEOUT:-120}"
fail=0
for shell in bash zsh; do
  command -v "$shell" >/dev/null 2>&1 || { echo "skip: $shell not installed"; continue; }
  for t in "$ROOT"/tests/test_*.sh; do
    ALIASX_ROOT="$ROOT" "$shell" "$t" </dev/null &
    pid=$!
    ( sleep "$LIMIT" && kill "$pid" 2>/dev/null && echo "TIMEOUT [$shell] $(basename "$t") after ${LIMIT}s" ) &
    watcher=$!
    if wait "$pid"; then
      echo "PASS [$shell] $(basename "$t")"
    else
      echo "FAIL [$shell] $(basename "$t")"
      fail=1
    fi
    kill "$watcher" 2>/dev/null; wait "$watcher" 2>/dev/null
  done
done
exit $fail
