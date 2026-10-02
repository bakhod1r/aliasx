# Changelog

All notable changes. Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), versions follow [SemVer](https://semver.org/).

## [1.0.0] - 2026-10-02

First stable release.

### Added
- 25 modules for bash and zsh on Linux and macOS: navigation, files, git, docker, podman,
  kubernetes/helm, terraform/ansible, devops, sysadmin, network, system, development,
  backend/API, databases, nginx, ssh/tmux, utilities, `.env` editing, cloud CLIs.
- Live hints in zsh and bash 4+: type a name and Space to see what it runs.
- Word search: type a word like `port` to list related commands; `aliasx find`.
- Profiles (`ALIASX_PROFILE=backend|devops|sysadmin|minimal`).
- Personal aliases: `aliasx add | rm | mine`, saved to `~/.aliasx.local.sh`.
- `aliasx conflicts`, `doctor`, `version`, `update`, `why`, `mode safe` (rm asks first).
- Tab completion for `aliasx`.
- One-command zsh setup: `setup/zsh-setup.sh` (oh-my-zsh, powerlevel10k, plugins, font).
- Docs site generated from module comments, with search, examples and source view.
- CI on Ubuntu and macOS, ShellCheck, docs freshness check.

### Safety
- Standard commands are not replaced by default; destructive actions ask first;
  bulk deletes are opt-in and need a typed phrase.
- Loads under `set -eu` and alongside oh-my-zsh aliases of the same name.
