. "$ALIASX_ROOT/tests/helpers.sh"

# Fake optional tools so conditional modules load.
stubs="$(mktemp -d)"
for t in git docker kubectl helm terraform tofu ansible npm pnpm bun python3 go cargo jq yq gh aws az gcloud lazygit systemctl apt brew psql redis-cli nginx podman mysql mysqldump tmux ssh ufw pm2; do
  printf '#!/bin/sh\nexit 0\n' > "$stubs/$t"; chmod +x "$stubs/$t"
done
PATH="$stubs:$PATH"
. "$ALIASX_ROOT/aliasx.sh"

# core
assert_function has
assert_function aliasx
assert_function reload
for a in c now week path; do assert_alias "$a"; done

# files
for a in grep cpi mvi rmi countfiles emptydirs dfh usage biggest du1 calc; do assert_alias "$a"; done
for f in ff fdir sha256file hgrep; do assert_function "$f"; done

# git
for a in g gs gst ga gaa gap gd gds gb gc gcm gcan gsw gswc grs grss gco gf gfa gp gpu gpf gl glr grb grba grbc glog gloga glast gwho; do assert_alias "$a"; done
for f in groot gundo gclean-preview gpristine; do assert_function "$f"; done
for a in ghpr ghprs ghruns; do assert_alias "$a"; done

# docker
for a in d dps dpsa di dlogf dstats dc dcu dcud dcd dcps dclf; do assert_alias "$a"; done
for f in dsh drun dip dstop-all dprune; do assert_function "$f"; done

# kubernetes
for a in k kg kgp kgpa kgs kgn klf kctx kctxs kns kev hm hmls; do assert_alias "$a"; done
for f in kuse knamespace kpf kdebug; do assert_function "$f"; done

# infra
for a in tf tfi tfp tfa tfv ap apcheck; do assert_alias "$a"; done

# db
for a in pg pgl pgls pgready pgsize pgconns rcli rping rinfo rmem rmon rlat rbig rget; do assert_alias "$a"; done
for f in pgq pgdump pgrestore rkeys; do assert_function "$f"; done

# podman
for a in pd pdps pdpsa pdi pdlogf pdstats pdc pdcu pdcud pdcd pdcps pdclf; do assert_alias "$a"; done
for f in pdsh pdrun pdprune; do assert_function "$f"; done

# mysql
for a in my myl myls myproc; do assert_alias "$a"; done
for f in myq mydump; do assert_function "$f"; done

# tmux, ssh
for a in tl ta tn sshkeys sshconf; do assert_alias "$a"; done
for f in sshgen sshcopy; do assert_function "$f"; done

# ufw, pm2
for a in ufws ufwa ufwd pm2l pm2logs pm2r; do assert_alias "$a"; done

# nginx
for a in ngt ngconf ngv ngsites; do assert_alias "$a"; done
for f in ngr ngrestart ngs nge nga; do assert_function "$f"; done

# dev
for a in ni nr nrd py gor got cargo-r; do assert_alias "$a"; done
for f in venv serve tlscheck; do assert_function "$f"; done

# net / system / cloud / tools
for f in myip lanip ports freeport psgrep clipcopy clippaste; do assert_function "$f"; done
for a in conns hosts dns ping5 curlh curlj pscpu psmem sc jc awswho azwho gcwho lg; do assert_alias "$a"; done

# Dangerous and replacing aliases are opt-in only.
refute_alias top
refute_alias cat
assert_eq "$(typeset -f docker-prune-all >/dev/null 2>&1 && echo yes)" "" "dangerous not loaded by default"

# Without tools, conditional aliases stay off.
rm -rf "$stubs"
hash -r
unalias k d tf 2>/dev/null
PATH="/usr/bin:/bin" . "$ALIASX_ROOT/aliasx.sh"
refute_alias k
refute_alias d
refute_alias tf

finish
