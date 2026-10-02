. "$ALIASX_ROOT/tests/helpers.sh"
. "$ALIASX_ROOT/aliasx.sh"

assert_function aliasx_find
out="$(aliasx_find port)"
for n in "ports" "freeport" "waitport" "tunnel"; do
  case "$out" in *"$n"*) ;; *) echo "  'port' missing $n"; _failures=$((_failures + 1)) ;; esac
done
# one line per command: name, then description
case "$out" in *"freeport PORT · kill what listens on PORT"*) ;; *) echo "  format: $out"; _failures=$((_failures + 1)) ;; esac

# case-insensitive, matches descriptions
case "$(aliasx_find CLIPBOARD)" in *clipcopy*) ;; *) echo "  case-insensitive desc match"; _failures=$((_failures + 1)) ;; esac

# internal helpers never listed
case "$(aliasx_find http)" in *_aliasx*) echo "  internal helper listed"; _failures=$((_failures + 1)) ;; esac

# not-loaded commands are not listed (no kubectl here)
PATH=/usr/bin:/bin
case "$(aliasx_find pod)" in *kgp*) echo "  listed unloaded kgp"; _failures=$((_failures + 1)) ;; esac

# aliases show the command they run
case "$(aliasx_find header)" in *"curlh → curl --head · response headers only"*) ;; *) echo "  alias line lacks command"; _failures=$((_failures + 1)) ;; esac

# word-start match: "port" must not hit "report"
case "$(aliasx_find port)" in *certfile*) echo "  matched inside word"; _failures=$((_failures + 1)) ;; esac

# no match
aliasx_find zzzqqq >/dev/null; assert_eq "$?" "1" "no match returns 1"
assert_eq "$(aliasx find freeport | head -1 | cut -c1-8)" "freeport" "aliasx find"
finish
