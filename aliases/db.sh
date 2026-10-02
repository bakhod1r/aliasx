# Databases: PostgreSQL (pg*), MySQL (my*), Redis (r*), MongoDB.

if has psql; then
  # == PostgreSQL
  alias pg='psql'  # psql
  alias pgl='psql -h localhost'  # psql to localhost
  alias pgls='psql -l'  # list databases
  alias pgready='pg_isready'  # is the server accepting connections
  alias pgsize='psql -c "SELECT datname, pg_size_pretty(pg_database_size(datname)) FROM pg_database ORDER BY pg_database_size(datname) DESC"'  # database sizes
  alias pgconns='psql -c "SELECT pid, usename, datname, state, left(query, 60) AS query FROM pg_stat_activity WHERE pid <> pg_backend_pid()"'  # active connections

  # pgq DB SQL — run one query
  #   $ pgq shop 'SELECT count(*) FROM orders'
  #    count
  #   -------
  #     1520
  #   (1 row)
  pgq() {
    [ "$#" -eq 2 ] || { echo "Usage: pgq <database> <sql>" >&2; return 2; }
    psql -d "$1" -c "$2"
  }

  # pgdump DB — dump to DB-YYYYmmdd-HHMMSS.dump (custom format)
  #   $ pgdump shop
  #   shop-20261002-103512.dump
  pgdump() {
    [ "$#" -eq 1 ] || { echo "Usage: pgdump <database>" >&2; return 2; }
    _f="$1-$(date +%Y%m%d-%H%M%S).dump"
    pg_dump -Fc -f "$_f" "$1" && echo "$_f"
    unset _f
  }

  # pgrestore FILE DB — restore a .dump into DB (no drop, no owners)
  #   $ pgrestore shop-20261002-103512.dump shop_copy
  #   (no output on success)
  pgrestore() {
    [ "$#" -eq 2 ] || { echo "Usage: pgrestore <file.dump> <database>" >&2; return 2; }
    pg_restore --no-owner -d "$2" "$1"
  }
fi

if has mysql; then
  # == MySQL / MariaDB
  alias my='mysql'  # mysql
  alias myl='mysql -h 127.0.0.1'  # mysql to localhost
  alias myls='mysql -e "SHOW DATABASES"'  # list databases
  alias myproc='mysql -e "SHOW FULL PROCESSLIST"'  # running queries

  # myq DB SQL — run one query
  #   $ myq shop 'SELECT count(*) FROM orders'
  #   +----------+
  #   | count(*) |
  #   +----------+
  #   |     1520 |
  #   +----------+
  myq() {
    [ "$#" -eq 2 ] || { echo "Usage: myq <database> <sql>" >&2; return 2; }
    mysql -D "$1" -e "$2"
  }

  # mydump DB — dump to DB-YYYYmmdd-HHMMSS.sql
  #   $ mydump shop
  #   shop-20261002-103512.sql
  mydump() {
    [ "$#" -eq 1 ] || { echo "Usage: mydump <database>" >&2; return 2; }
    _f="$1-$(date +%Y%m%d-%H%M%S).sql"
    mysqldump --single-transaction "$1" > "$_f" && echo "$_f"
    unset _f
  }
fi

if has redis-cli; then
  # == Redis
  alias rcli='redis-cli'  # redis-cli
  alias rping='redis-cli ping'  # PONG if alive
  alias rinfo='redis-cli info'  # server info
  alias rmem='redis-cli info memory'  # memory usage
  alias rmon='redis-cli monitor'  # watch every command live
  alias rlat='redis-cli --latency'  # measure latency
  alias rbig='redis-cli --bigkeys'  # find biggest keys
  alias rget='redis-cli get'  # get a key

  # rkeys [PATTERN] — list keys with SCAN (safe on big databases)
  #   $ rkeys 'session:*'
  #   session:9f2c
  #   session:a71b
  rkeys() { redis-cli --scan --pattern "${1:-*}"; }
fi

has mongosh && alias mongol='mongosh mongodb://127.0.0.1:27017'  # mongosh to localhost
