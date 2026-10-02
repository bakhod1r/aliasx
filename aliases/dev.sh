# Development: Node, Python, Go, Rust, Java, JSON, TLS.

if has npm; then
  # == npm
  alias ni='npm install'  # npm install
  alias nid='npm install --save-dev'  # npm install dev dependency
  alias nr='npm run'  # npm run script
  alias nrd='npm run dev'  # npm run dev
  alias nrb='npm run build'  # npm run build
  alias nrt='npm test'  # npm test
fi
if has pnpm; then
  # == pnpm (pr is coreutils, so pnr)
  alias pn='pnpm'  # pnpm
  alias pni='pnpm install'  # pnpm install
  alias pna='pnpm add'  # pnpm add
  alias pnr='pnpm run'  # pnpm run script
  alias pnd='pnpm dev'  # pnpm dev
fi
if has bun; then
  # == bun
  alias buni='bun install'  # bun install
  alias bunr='bun run'  # bun run script
  alias bund='bun run dev'  # bun run dev
fi

if has pm2; then
  # == pm2
  alias pm2l='pm2 list'  # running apps
  alias pm2logs='pm2 logs'  # follow logs
  alias pm2r='pm2 restart'  # restart app
fi

if has python3; then
  # == Python
  alias py='python3'  # python3
  alias pipi='python3 -m pip install'  # pip install
  alias pipu='python3 -m pip install --upgrade'  # pip upgrade package

  # venv [DIR] — create (if missing) and activate virtualenv (default .venv)
  #   $ venv
  #   (.venv) $
  venv() {
    _d="${1:-.venv}"
    [ -d "$_d" ] || python3 -m venv "$_d" || { unset _d; return 1; }
    . "$_d/bin/activate"; unset _d
  }

  # serve [PORT] [DIR] — static HTTP server on 127.0.0.1 (default 8000)
  #   $ serve 9000
  #   Serving . at http://127.0.0.1:9000
  serve() {
    echo "Serving ${2:-.} at http://127.0.0.1:${1:-8000}"
    python3 -m http.server "${1:-8000}" --bind 127.0.0.1 --directory "${2:-.}"
  }
fi

if has go; then
  # == Go
  alias gor='go run'  # go run
  alias gob='go build'  # go build
  alias got='go test ./...'  # go test all packages
  alias gomt='go mod tidy'  # go mod tidy
  alias govet='go vet ./...'  # go vet all packages
fi

if has cargo; then
  # == Rust (cargo- prefix; cc and cb clash with compilers)
  alias cargo-r='cargo run'  # cargo run
  alias cargo-b='cargo build'  # cargo build
  alias cargo-br='cargo build --release'  # release build
  alias cargo-t='cargo test'  # cargo test
  alias cargo-c='cargo check'  # type-check only
  alias cargo-l='cargo clippy'  # clippy lints
fi

if has mvn; then
  # == Maven and Gradle
  alias mvnc='mvn clean'  # maven clean
  alias mvni='mvn install'  # maven install
  alias mvnt='mvn test'  # maven test
fi
if has gradle; then
  alias gradleb='gradle build'  # gradle build
  alias gradlet='gradle test'  # gradle test
fi



# == TLS
# tlscheck HOST[:PORT] — show certificate subject, issuer, dates
#   $ tlscheck example.com
#   subject=CN=example.com
#   issuer=C=US, O=DigiCert Inc, CN=DigiCert Global G3 TLS ECC SHA384 2020 CA1
#   notBefore=Jan 15 00:00:00 2026 GMT
#   notAfter=Jan 15 23:59:59 2027 GMT
tlscheck() {
  [ "$#" -eq 1 ] || { echo "Usage: tlscheck <host[:port]>" >&2; return 2; }
  _h="${1%%:*}"; _p="${1##*:}"; [ "$_h" = "$_p" ] && _p=443
  openssl s_client -connect "$_h:$_p" -servername "$_h" </dev/null 2>/dev/null |
    openssl x509 -noout -subject -issuer -dates
  unset _h _p
}

