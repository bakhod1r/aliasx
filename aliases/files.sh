# Files: safe operations, search, disk, archives, history.

# == Safe operations
# Explicit variants; standard cp/mv/rm are left untouched.
alias cpi='cp -i'  # copy, ask before overwriting
alias mvi='mv -i'  # move, ask before overwriting
alias rmi='rm -i'  # remove, ask for each file
alias lni='ln -i'  # link, ask before overwriting
alias md='mkdir -p'  # make directory with parents
alias rd='rmdir'  # remove empty directory

# backup FILE — copy to FILE.bak.YYYYmmdd-HHMMSS
#   $ backup nginx.conf
#   nginx.conf.bak created
function backup {
  [ "$#" -eq 1 ] || { echo "Usage: backup <file>" >&2; return 2; }
  cp -p -- "$1" "$1.bak.$(date +%Y%m%d-%H%M%S)" && echo "$1.bak created"
}

# extract ARCHIVE — unpack by extension
#   $ extract release.tar.gz
#   (files unpacked into current folder)
function extract {
  [ "$#" -eq 1 ] || { echo "Usage: extract <archive>" >&2; return 2; }
  [ -f "$1" ] || { echo "extract: '$1' not a file" >&2; return 1; }
  case "$1" in
    *.tar.gz|*.tgz)   tar -xzf "$1" ;;
    *.tar.bz2|*.tbz2) tar -xjf "$1" ;;
    *.tar.xz|*.txz)   tar -xJf "$1" ;;
    *.tar.zst)        tar --zstd -xf "$1" ;;
    *.tar)            tar -xf "$1" ;;
    *.gz)             gunzip "$1" ;;
    *.bz2)            bunzip2 "$1" ;;
    *.xz)             unxz "$1" ;;
    *.zip)            unzip "$1" ;;
    *.7z)             7z x "$1" ;;
    *.rar)            unrar x "$1" ;;
    *) echo "extract: unknown format '$1'" >&2; return 1 ;;
  esac
}

# == Everyday
alias cx='chmod +x'  # make executable
alias tailf='tail -f'  # follow a file

# cl DIR — cd into DIR and list it
#   $ cl src
#   api/  web/  main.go  go.mod
function cl { cd -- "${1:-$HOME}" && ls; }

# tmpd — create a temp directory and enter it
#   $ tmpd
#   /tmp/tmp.Xk3p9QzL
function tmpd { _d="$(mktemp -d)" && cd -- "$_d" && pwd; unset _d; }

# newest [N] — N most recently modified entries (default 10)
#   $ newest 3
#   notes.md
#   main.go
#   go.mod
function newest { ls -t | head -n "${1:-10}"; }

# perms FILE — octal permissions
#   $ perms .env
#   600 .env
function perms {
  [ "$#" -ge 1 ] || { echo "Usage: perms <file>..." >&2; return 2; }
  if stat -c '%a %n' -- "$1" >/dev/null 2>&1; then stat -c '%a %n' -- "$@"; else stat -f '%Lp %N' -- "$@"; fi
}

# dl URL — download into current directory (keeps remote name)
#   $ dl https://example.com/tool.tar.gz
#     % Total    % Received ...  100  4.1M
function dl {
  [ "$#" -eq 1 ] || { echo "Usage: dl <url>" >&2; return 2; }
  if has curl; then curl -fL -O -- "$1"; else wget -- "$1"; fi
}

# tgz DIR — pack DIR into DIR.tar.gz
#   $ tgz project
#   project.tar.gz
function tgz {
  [ "$#" -eq 1 ] || { echo "Usage: tgz <dir>" >&2; return 2; }
  _n="${1%/}"; tar -czf "$_n.tar.gz" -- "$_n" && echo "$_n.tar.gz"; unset _n
}

# zipd DIR — pack DIR into DIR.zip
#   $ zipd project
#   project.zip
function zipd {
  [ "$#" -eq 1 ] || { echo "Usage: zipd <dir>" >&2; return 2; }
  _n="${1%/}"; zip -qr "$_n.zip" "$_n" && echo "$_n.zip"; unset _n
}

# == Edit text
# prepend FILE [TEXT] — add TEXT (or stdin) as first line(s) of FILE
#   $ prepend run.sh '#!/bin/sh'
#   (first line of run.sh is now #!/bin/sh)
function prepend {
  [ "$#" -ge 1 ] || { echo "Usage: prepend <file> [text]" >&2; return 2; }
  [ -f "$1" ] || { echo "prepend: '$1' not a file" >&2; return 1; }
  _t="$(mktemp)" || return 1
  { if [ "$#" -ge 2 ]; then printf '%s\n' "$2"; else cat; fi; cat -- "$1"; } > "$_t" &&
    cat -- "$_t" > "$1"
  command rm -f -- "$_t"; unset _t
}

# append FILE [TEXT] — add TEXT (or stdin) as last line(s) of FILE
#   $ append .gitignore node_modules
#   (last line of .gitignore is now node_modules)
function append {
  [ "$#" -ge 1 ] || { echo "Usage: append <file> [text]" >&2; return 2; }
  [ -s "$1" ] && [ "$(tail -c 1 -- "$1")" != "" ] && printf '\n' >> "$1"
  if [ "$#" -ge 2 ]; then printf '%s\n' "$2" >> "$1"; else cat >> "$1"; fi
}

# == Search
alias grep='grep --color=auto'  # grep with colors
alias egrep='grep -E --color=auto'  # extended regex grep
alias fgrep='grep -F --color=auto'  # fixed-string grep
alias countfiles='find . -type f | wc -l'  # count files below here
alias countdirs='find . -type d | wc -l'  # count folders below here
alias emptydirs='find . -type d -empty'  # find empty folders
alias emptyfiles='find . -type f -empty'  # find empty files

# ff PATTERN — find files whose name contains PATTERN
#   $ ff config
#   ./app/config.yaml
#   ./docs/config.md
function ff {
  [ "$#" -eq 1 ] || { echo "Usage: ff <pattern>" >&2; return 2; }
  find . -type f -iname "*$1*"
}

# ftext TEXT — find TEXT in files below here (skips .git, node_modules)
#   $ ftext TODO
#   ./api/user.go:42:// TODO: validate email
#   ./web/app.js:7:// TODO: remove debug
function ftext {
  [ "$#" -ge 1 ] || { echo "Usage: ftext <text>" >&2; return 2; }
  grep -rnI --exclude-dir=.git --exclude-dir=node_modules -- "$*" .
}

# fdir PATTERN — find directories whose name contains PATTERN
#   $ fdir test
#   ./tests
#   ./api/testdata
function fdir {
  [ "$#" -eq 1 ] || { echo "Usage: fdir <pattern>" >&2; return 2; }
  find . -type d -iname "*$1*"
}

# == Disk
alias dfh='df -h'  # disk free, human sizes
alias dfi='df -i'  # inode usage
alias usage='du -sh .'  # size of current folder
alias biggest='du -sh ./* 2>/dev/null | sort -h | tail -20'  # 20 biggest items here
if [ "$ALIASX_OS" = macos ]; then
  alias du1='du -h -d 1'  # size of each subfolder
else
  alias du1='du -h --max-depth=1'  # size of each subfolder
fi

# == Calculate and hash
alias calc='bc -l'  # calculator

# sha256file FILE — SHA-256 checksum on Linux or macOS
#   $ sha256file app.tar.gz
#   3a7bd3e2360a3d29eea436fcfb7e44c735d117c42d1c1835420b6b9942dd4f1b  app.tar.gz
function sha256file {
  [ "$#" -eq 1 ] || { echo "Usage: sha256file <file>" >&2; return 2; }
  if has sha256sum; then sha256sum -- "$1"; else shasum -a 256 -- "$1"; fi
}

# == History
alias h='history'  # shell history

# hgrep PATTERN — search shell history
#   $ hgrep docker
#     412  docker compose up -d
#     418  docker logs api
function hgrep {
  [ "$#" -ge 1 ] || { echo "Usage: hgrep <pattern>" >&2; return 2; }
  fc -l 1 | grep -i -- "$*"
}
