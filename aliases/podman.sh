# Podman (pd*): same shape as the docker module.
has podman || return 0

# == Containers and images
alias pd='podman'  # podman
alias pdps='podman ps'  # running containers
alias pdpsa='podman ps --all'  # all containers
alias pdi='podman images'  # images
alias pdvol='podman volume ls'  # volumes
alias pdpods='podman pod ps'  # pods
alias pdlog='podman logs'  # container logs
alias pdlogf='podman logs --follow --tail 200'  # follow last 200 log lines
alias pdstats='podman stats'  # live resource usage
alias pdbuild='podman build'  # build image
alias pdpull='podman pull'  # pull image
alias pddf='podman system df'  # podman disk usage

# pdsh CONTAINER [CMD] — shell into container (bash, else sh)
#   $ pdsh api
#   root@4f2a9c1b:/app#
function pdsh {
  [ "$#" -ge 1 ] || { echo "Usage: pdsh <container> [command]" >&2; return 2; }
  _c="$1"; shift
  if [ "$#" -gt 0 ]; then podman exec -it "$_c" "$@"
  elif podman exec "$_c" test -x /bin/bash 2>/dev/null; then podman exec -it "$_c" /bin/bash
  else podman exec -it "$_c" /bin/sh; fi
  unset _c
}

# pdrun IMAGE [CMD] — run throwaway interactive container
#   $ pdrun alpine
#   / #
function pdrun {
  [ "$#" -ge 1 ] || { echo "Usage: pdrun <image> [command]" >&2; return 2; }
  podman run --rm -it "$@"
}

# pdprune — show usage, then podman system prune after y/N
#   $ pdprune
#   TYPE     TOTAL  RECLAIMABLE
#   Images   9      1.1GB (40%)
#   Prune unused Podman data? [y/N] n
#   Cancelled.
function pdprune {
  podman system df
  printf 'Prune unused Podman data? [y/N] '; read -r _a
  case "$_a" in y|Y|yes) podman system prune ;; *) echo "Cancelled." ;; esac # allow-destructive
  unset _a
}

# == Compose
alias pdc='podman compose'  # podman compose
alias pdcu='podman compose up'  # compose up
alias pdcud='podman compose up --detach'  # compose up in background
alias pdcd='podman compose down'  # compose down
alias pdcps='podman compose ps'  # compose services
alias pdclf='podman compose logs --follow --tail 200'  # follow compose logs
