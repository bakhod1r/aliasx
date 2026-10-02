# Docker and Docker Compose.
has docker || return 0

# == Containers and images
alias d='docker'  # docker
alias dps='docker ps'  # running containers
alias dpsa='docker ps --all'  # all containers
alias di='docker images'  # images
alias dvol='docker volume ls'  # volumes
alias dnet='docker network ls'  # networks
alias dlog='docker logs'  # container logs
alias dlogf='docker logs --follow --tail 200'  # follow last 200 log lines
alias dstats='docker stats'  # live resource usage
alias dinspect='docker inspect'  # inspect object
alias dbuild='docker build'  # build image
alias dpull='docker pull'  # pull image
alias ddf='docker system df'  # docker disk usage

# dsh CONTAINER [CMD] — shell into container (bash, else sh)
#   $ dsh api
#   root@4f2a9c1b:/app#
function dsh {
  [ "$#" -ge 1 ] || { echo "Usage: dsh <container> [command]" >&2; return 2; }
  _c="$1"; shift
  if [ "$#" -gt 0 ]; then docker exec -it "$_c" "$@"
  elif docker exec "$_c" test -x /bin/bash 2>/dev/null; then docker exec -it "$_c" /bin/bash
  else docker exec -it "$_c" /bin/sh; fi
  unset _c
}

# drun IMAGE [CMD] — run throwaway interactive container
#   $ drun alpine
#   / #
function drun {
  [ "$#" -ge 1 ] || { echo "Usage: drun <image> [command]" >&2; return 2; }
  docker run --rm -it "$@"
}

# dip CONTAINER — print container IP
#   $ dip api
#   172.18.0.3
function dip {
  [ "$#" -eq 1 ] || { echo "Usage: dip <container>" >&2; return 2; }
  docker inspect --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$1"
}

# dstop-all — stop all running containers after y/N
#   $ dstop-all
#   CONTAINER ID   IMAGE      NAMES
#   4f2a9c1b       api:dev    api
#   Stop all running containers? [y/N] n
#   Cancelled.
function dstop-all {
  _ids="$(docker ps -q)"
  [ -n "$_ids" ] || { echo "No running containers."; return 0; }
  docker ps
  printf 'Stop all running containers? [y/N] '; read -r _a
  case "$_a" in y|Y|yes) echo "$_ids" | xargs docker stop ;; *) echo "Cancelled." ;; esac
  unset _ids _a
}

# dprune — show usage, then docker system prune after y/N
#   $ dprune
#   TYPE            TOTAL     RECLAIMABLE
#   Images          14        3.2GB (61%)
#   Prune unused Docker data? [y/N] n
#   Cancelled.
function dprune {
  docker system df
  printf 'Prune unused Docker data? [y/N] '; read -r _a
  case "$_a" in y|Y|yes) docker system prune ;; *) echo "Cancelled." ;; esac # allow-destructive
  unset _a
}

# == Compose
alias dc='docker compose'  # docker compose
alias dcu='docker compose up'  # compose up
alias dcud='docker compose up --detach'  # compose up in background
alias dcub='docker compose up --detach --build'  # rebuild and up in background
alias dcd='docker compose down'  # compose down
alias dcps='docker compose ps'  # compose services
alias dcl='docker compose logs'  # compose logs
alias dclf='docker compose logs --follow --tail 200'  # follow last 200 compose log lines
alias dcb='docker compose build'  # compose build
alias dcpull='docker compose pull'  # pull compose images
alias dcr='docker compose restart'  # restart compose services
alias dcconfig='docker compose config'  # show resolved compose file
