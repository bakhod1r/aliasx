. "$ALIASX_ROOT/tests/helpers.sh"
. "$ALIASX_ROOT/aliasx.sh"
assert_function _aliasx_complete_words
flat() { _aliasx_complete_words "$@" | tr '\n' ' '; }

w="$(flat 1 '')"
for s in modules list check find why mode add rm mine conflicts profile profiles; do
  case " $w " in *" $s "*) ;; *) echo "  missing subcommand $s"; _failures=$((_failures + 1)) ;; esac
done
case " $(flat 2 list) " in *" git "*" net "*) ;; *) echo "  list → modules"; _failures=$((_failures + 1)) ;; esac
assert_eq "$(flat 2 mode)" "normal safe " "mode values"
case " $(flat 2 why) " in *" freeport "*) ;; *) echo "  why → names"; _failures=$((_failures + 1)) ;; esac
finish
