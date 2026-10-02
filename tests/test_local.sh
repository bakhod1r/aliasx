. "$ALIASX_ROOT/tests/helpers.sh"
tmp="$(mktemp -d)"
ALIASX_LOCAL="$tmp/local.sh"
. "$ALIASX_ROOT/aliasx.sh"

aliasx add deploy './scripts/deploy.sh --prod' "deploy to production" >/dev/null
assert_alias deploy                                       # usable right away
assert_eq "$(aliasx why deploy)" "deploy → ./scripts/deploy.sh --prod · deploy to production" "hint for own alias"
case "$(aliasx find production)" in *deploy*) ;; *) echo "  find own alias"; _failures=$((_failures + 1)) ;; esac

# quotes survive
aliasx add greet "echo 'hi there'" "say hi" >/dev/null
assert_eq "$(bash -c 'shopt -s expand_aliases; . "$1"
greet' _ "$ALIASX_LOCAL")" "hi there" "single quotes in command"
assert_eq "$(aliasx why greet)" "greet → echo 'hi there' · say hi" "hint unescapes quotes"

# update replaces, no duplicate line
aliasx add deploy './scripts/deploy.sh --staging' "deploy to staging" >/dev/null
assert_eq "$(grep -c '^alias deploy=' "$ALIASX_LOCAL")" "1" "update keeps one line"

# persisted: a fresh load sees them
unalias deploy greet
. "$ALIASX_ROOT/aliasx.sh"
assert_alias deploy; assert_alias greet

# list and remove
case "$(aliasx mine)" in *deploy*greet*|*greet*deploy*) ;; *) echo "  aliasx mine"; _failures=$((_failures + 1)) ;; esac
aliasx rm greet >/dev/null
refute_alias greet
assert_eq "$(grep -c greet "$ALIASX_LOCAL")" "0" "rm deletes line"

# validation
aliasx add 'bad name' 'x' >/dev/null 2>&1; assert_eq "$?" "2" "invalid name"
aliasx add onlyname >/dev/null 2>&1; assert_eq "$?" "2" "missing command"
aliasx rm nothere >/dev/null 2>&1; assert_eq "$?" "1" "rm unknown"

command rm -r "$tmp"
finish
