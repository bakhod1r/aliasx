# Security

aliasx is shell code that runs in your interactive shell. Treat it like any code you source.

- Review before installing: `grep -rn 'sudo\|eval\|curl\|rm ' aliases optional`.
- Nothing runs at load time except defining aliases and functions. There is no network
  access at load; `aliasx update` only runs `git pull --ff-only` when you call it.
- `sudo` appears only in package, power, service, firewall and nginx commands, never implicitly.
- Destructive commands ask first; bulk deletes live in `optional/dangerous.sh`, which is
  not loaded unless you set `ALIASX_ENABLE="dangerous"`.

## Reporting a vulnerability

Please do not open a public issue. Use GitHub's private vulnerability reporting
(Security → Report a vulnerability) on this repository.
