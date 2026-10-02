# Opt-in: destructive helpers. Each one shows targets and asks for a phrase.
# Enable only for maintenance: ALIASX_ENABLE="dangerous"

# confirm PROMPT PHRASE — true only if user types PHRASE
#   $ confirm 'Wipe cache?' WIPE && rm -r cache
#   Wipe cache? Type WIPE to continue: WIPE
confirm() {
  printf '%s Type %s to continue: ' "$1" "$2"
  read -r _a
  [ "$_a" = "$2" ]; _rc=$?; unset _a; return $_rc
}

# == Docker
# docker-rm-stopped — remove all exited containers
#   $ docker-rm-stopped
#   CONTAINER ID  STATUS
#   9a1b...       Exited (0)
#   Remove every stopped container? Type REMOVE-STOPPED to continue:
docker-rm-stopped() {
  docker ps --all --filter status=exited
  confirm "Remove every stopped container?" REMOVE-STOPPED || return 1
  docker ps --quiet --all --filter status=exited | xargs docker rm # allow-destructive
}

# docker-prune-all — remove all unused data including images
#   $ docker-prune-all
#   Remove all unused Docker data, including images? Type PRUNE-DOCKER to continue:
docker-prune-all() {
  docker system df
  confirm "Remove all unused Docker data, including images?" PRUNE-DOCKER || return 1
  docker system prune --all # allow-destructive
}

# == Databases
# redis-flush — delete every key in the current Redis database
#   $ redis-flush
#   (integer) 1520
#   Delete every key in this Redis database? Type FLUSH-REDIS to continue:
redis-flush() {
  redis-cli dbsize
  confirm "Delete every key in this Redis database?" FLUSH-REDIS || return 1
  redis-cli flushdb # allow-destructive
}

# pg-dropdb DB — drop a PostgreSQL database (type its name to confirm)
#   $ pg-dropdb shop_copy
#   Drop database shop_copy permanently? Type shop_copy to continue:
pg-dropdb() {
  [ "$#" -eq 1 ] || { echo "Usage: pg-dropdb <database>" >&2; return 2; }
  confirm "Drop database $1 permanently?" "$1" || return 1
  dropdb "$1" # allow-destructive
}
