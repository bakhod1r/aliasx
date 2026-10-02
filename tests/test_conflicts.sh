. "$ALIASX_ROOT/tests/helpers.sh"
fake="$(mktemp -d)"; mkdir "$fake/bin"
printf '#!/bin/sh\n' > "$fake/bin/gs"; chmod +x "$fake/bin/gs"   # e.g. ghostscript
printf '#!/bin/sh\n' > "$fake/bin/git"; chmod +x "$fake/bin/git"
printf "alias dc='cd ~/dev'\nmkcd() { :; }\n" > "$fake/.zshrc"
PATH="$fake/bin:/usr/bin:/bin"
. "$ALIASX_ROOT/aliasx.sh"

out="$(HOME="$fake" aliasx conflicts)"
case "$out" in *"gs"*"$fake/bin/gs"*) ;; *) echo "  missed PATH command gs: $out"; _failures=$((_failures + 1)) ;; esac
case "$out" in *"dc"*".zshrc"*) ;; *) echo "  missed rc alias dc"; _failures=$((_failures + 1)) ;; esac
case "$out" in *"mkcd"*".zshrc"*) ;; *) echo "  missed rc function mkcd"; _failures=$((_failures + 1)) ;; esac
# deliberate overrides are not reported
case "$out" in *" ls "*|"ls "*) echo "  reported intended ls"; _failures=$((_failures + 1)) ;; esac

# install.sh prints the report
touch "$fake/.bashrc"
inst="$(HOME="$fake" PATH="$PATH" bash "$ALIASX_ROOT/install.sh")"
case "$inst" in *"gs"*) ;; *) echo "  install did not report conflicts: $inst"; _failures=$((_failures + 1)) ;; esac
command rm -r "$fake"
finish
