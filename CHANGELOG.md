# Changelog

All notable changes. Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), versions follow [SemVer](https://semver.org/).

## [Unreleased]

## [1.1.1] - 2026-10-03

### Added
- `aliasx set`: short name for `aliasx configure`.

## [1.1.0] - 2026-10-03

### Added
- `aliasx configure`: dark full-screen wizard (Profile, Modules, Optional, Mode, Save)
  that writes `~/.aliasx.conf`. The loader reads it safely (known keys, plain values);
  variables set before loading still win.
- Typing a program that is not installed (e.g. `tree2` without `tree`) offers to
  install it with brew/apt/dnf/pacman/apk, then runs the command. Asks first;
  `ALIASX_AUTOINSTALL=0` turns it off. An existing not-found handler is kept.
- CI on Alpine and Fedora, and integration tests against real PostgreSQL, Redis and nginx.
- Issue and PR templates, Dependabot for GitHub Actions.

### Fixed
- Loading aliasx twice (install line + oh-my-zsh plugin, or `reload`) no longer drops
  the Space key widget of other plugins such as zsh-autocomplete.
- Containers: `asroot` replaces hardcoded `sudo`, so package, service and nginx commands
  work as root or where sudo is not installed.
- nginx `ngr`/`ngrestart`/`ngs` use systemctl only when systemd is actually running.
- Alpine/busybox: `bigfiles`, `logsize`, `biggest` no longer need `sort -h`;
  `b64d`/`ksecret` use `base64 -d`; `ftext` works without `grep --exclude-dir`;
  `bigfiles` sizes work with busybox `find`.

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
