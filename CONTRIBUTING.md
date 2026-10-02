# Contributing

## Adding an alias or function

1. Put it in the module that fits (`aliases/<module>.sh`). Tool-specific code goes
   inside `if has <tool>; then … fi` so it only loads when the tool exists.
2. Every alias ends with a description comment:
   `alias gs='git status --short --branch'  # short status with branch`
3. Every function has a doc line, an example and its output above it, and uses `function name {`:
   ```sh
   # ports [PORT] — listening TCP ports, or who listens on PORT
   #   $ ports 3000
   #   node  4123 ali  23u IPv4  TCP *:3000 (LISTEN)
   function ports { … }
   ```
4. Rules (checked by tests):
   - the alias name is shorter than the command it runs;
   - no name is defined in two modules and none hides a real program (`aliasx conflicts`);
   - anything destructive asks first (`yesno`), bulk deletes go to `optional/dangerous.sh`;
   - no `sudo` outside `system`, `admin` and `nginx` modules.

## Checks before a pull request

```sh
./tests/run.sh                                   # bash and zsh
tests/integration/run-docker.sh                  # real PostgreSQL, Redis, nginx (needs Docker)
for f in aliasx.sh install.sh setup/*.sh aliases/*.sh optional/*.sh tests/*.sh; do shellcheck "$f"; done
python3 tools/gendocs.py                         # commit the regenerated docs/
```

## Releasing

1. Update `VERSION` and `CHANGELOG.md`.
2. Commit, then tag: `git tag v$(cat VERSION) && git push --tags`.
   The release workflow checks the tag matches `VERSION` and publishes the GitHub release.
