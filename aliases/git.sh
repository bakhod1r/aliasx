# Git and GitHub CLI.
has git || return 0

# == Status and staging
alias g='git'  # git
alias gs='git status --short --branch'  # short status with branch
alias gst='git status'  # full status
alias ga='git add'  # stage files
alias gaa='git add --all'  # stage everything
alias gap='git add --patch'  # stage hunks interactively

# == Diff
alias gd='git diff'  # unstaged diff
alias gds='git diff --staged'  # staged diff
alias gdw='git diff --word-diff'  # word-level diff

# == Branches
alias gb='git branch'  # list branches
alias gba='git branch --all'  # list local and remote branches
alias gbd='git branch --delete'  # delete merged branch
alias gsw='git switch'  # switch branch
alias gswc='git switch --create'  # create and switch branch
alias gco='git checkout'  # checkout
alias gcb='git checkout -b'  # create branch via checkout

# == Commit
alias gc='git commit'  # commit
alias gcm='git commit -m'  # commit with message
alias gca='git commit --amend'  # amend last commit
alias gcan='git commit --amend --no-edit'  # amend last commit, keep message
alias grs='git restore'  # discard file changes
alias grss='git restore --staged'  # unstage files

# == Remote
alias gf='git fetch'  # fetch
alias gfa='git fetch --all --prune'  # fetch all remotes, prune
alias gp='git push'  # push
alias gpu='git push --set-upstream origin HEAD'  # push and set upstream
alias gpf='git push --force-with-lease'  # force push, safe (with lease)
alias gl='git pull'  # pull
alias glr='git pull --rebase'  # pull with rebase
alias gremotes='git remote --verbose'  # list remotes with URLs

# == Merge and rebase
alias gm='git merge'  # merge
alias gma='git merge --abort'  # abort merge
alias grb='git rebase'  # rebase
alias grba='git rebase --abort'  # abort rebase
alias grbc='git rebase --continue'  # continue rebase

# == Stash and tags
alias gsta='git stash push'  # stash changes
alias gstp='git stash pop'  # apply and drop last stash
alias gstl='git stash list'  # list stashes
alias gtags='git tag --sort=-creatordate'  # tags, newest first

# == Log
alias glog='git log --oneline --decorate --graph'  # one-line graph log
alias gloga='git log --oneline --decorate --graph --all'  # graph log, all branches
alias glast='git log -1 HEAD --stat'  # last commit with stats
alias gwho='git shortlog --summary --numbered'  # commits per author

# groot — print repository root
#   $ groot
#   /home/ali/projects/shop
function groot { git rev-parse --show-toplevel; }

# gundo — undo last commit, keep changes staged
#   $ gundo
#   (last commit undone, changes stay staged)
function gundo { git reset --soft HEAD~1; }

# gclean-preview — show untracked files git clean would remove
#   $ gclean-preview
#   Would remove build/
#   Would remove tmp.log
function gclean-preview { git clean -nd; }

# gpristine — discard all changes after typing PRISTINE
#   $ gpristine
#    M api/user.go
#   ?? tmp.log
#   Discard tracked changes and remove untracked files. Type PRISTINE to continue: no
#   Cancelled.
function gpristine {
  git status --short
  printf 'Discard tracked changes and remove untracked files. Type PRISTINE to continue: '
  read -r _a
  [ "$_a" = PRISTINE ] || { echo "Cancelled."; unset _a; return 1; }
  unset _a
  git reset --hard HEAD && git clean -fd # allow-destructive
}

# == Work in progress
# gwip — commit everything as a temporary WIP commit
#   $ gwip
#   [main 3f1c9b2] --wip-- [skip ci]
function gwip { git add -A && git commit --no-verify -qm "--wip-- [skip ci]" && git log -1 --oneline; }

# gunwip — undo the last commit if it is a WIP commit, keep changes
#   $ gunwip
#   undid 3f1c9b2 --wip-- [skip ci]
function gunwip {
  [ "$(git log -1 --format=%s)" = "--wip-- [skip ci]" ] || { echo "gunwip: last commit is not a WIP commit" >&2; return 1; }
  echo "undid $(git log -1 --oneline)"; git reset -q HEAD~1
}

# gfixup COMMIT — commit staged changes as a fixup of COMMIT, then autosquash
#   $ gfixup 3f1c9b2
#   [main 9a1b2c3] fixup! add login form
#   Successfully rebased and updated refs/heads/main.
function gfixup {
  [ "$#" -eq 1 ] || { echo "Usage: gfixup <commit>" >&2; return 2; }
  git commit --fixup="$1" && GIT_SEQUENCE_EDITOR=: git rebase -i --autosquash "$1~1"
}

# gclean-branches — delete local branches already merged into the current one, after y/N
#   $ gclean-branches
#   feature/login
#   fix/typo
#   Delete these merged branches? [y/N] y
function gclean-branches {
  _b="$(git branch --merged | grep -v -E '^\*|^[[:space:]]*(main|master|develop)$' | sed 's/^[[:space:]]*//')"
  [ -n "$_b" ] || { echo "No merged branches."; unset _b; return 0; }
  echo "$_b"
  yesno "Delete these merged branches?" && echo "$_b" | xargs git branch -d
  unset _b
}

# gbl FILE [LINE] — who changed FILE (or one LINE of it), ignoring whitespace
#   $ gbl api/user.go 42
#   3f1c9b2 (Ali 2026-09-30 42) if err := validate(u); err != nil {
function gbl {
  [ "$#" -ge 1 ] || { echo "Usage: gbl <file> [line]" >&2; return 2; }
  if [ -n "${2:-}" ]; then git blame -w -L "$2,$2" -- "$1"; else git blame -w -- "$1"; fi
}

# == GitHub CLI
if has gh; then
  alias ghpr='gh pr view --web'  # open PR in browser
  alias ghprs='gh pr list'  # list PRs
  alias ghissues='gh issue list'  # list issues
  alias ghrepo='gh repo view --web'  # open repo in browser
  alias ghruns='gh run list'  # list workflow runs
  alias ghwatch='gh run watch'  # watch workflow run
fi
