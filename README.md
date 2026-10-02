# aliasx

Safe, modular shell aliases for bash and zsh on Linux and macOS.
Docs: `docs/` (GitHub Pages), one page per module.

## Install

```sh
git clone https://github.com/bakhod1r/aliasx ~/.aliasx
~/.aliasx/install.sh            # adds a source line to ~/.bashrc and ~/.zshrc
~/.aliasx/install.sh --uninstall
```

oh-my-zsh: clone into `$ZSH_CUSTOM/plugins/aliasx` and add `aliasx` to `plugins=(...)`.

## Configure

```sh
export ALIASX_DISABLE="docker k8s"      # skip default modules
export ALIASX_ENABLE="modern dangerous"  # load opt-in modules
```

```sh
aliasx modules        # list modules
aliasx list git       # show a module's aliases
aliasx check gs k tf  # is a name taken?
aliasx find port      # commands related to a word (also shown live in zsh)
aliasx why lni        # lni → ln -i · link, ask before overwriting
aliasx mode safe      # rm lists targets and asks [Y/n]; ALIASX_MODE=safe to keep
```

## Modules

| Module | Covers |
|--------|--------|
| `core` | `has`, `c`, `e`, `envg`, `reload`, `now`, `path`, `aliasx`, safe mode |
| `hints` | type a name + Space: shows what it does |
| `nav` | `..`–`.....`, `mkcd`, `up`, `croot`, `ll`/`la`/`l` (folders first, marked `/`), `ldirs`, `lfiles` |
| `files` | `cpi`/`mvi`/`rmi`, `extract`, `backup`, `cl`, `cx`, `tailf`, `ftext`, `newest`, `perms`, `tmpd`, `dl`, `tgz`, `zipd`, `prepend`, `append`, `ff`, `fdir`, `dfh`, `du1`, `biggest`, `hgrep` |
| `git` | `gs`, `gaa`, `gcm`, `gsw`, `gpu`, `gpf`, `glog`, `gundo`, `gpristine`, GitHub CLI |
| `docker` | `dps`, `dlogf`, `dsh`, `drun`, `dip`, `dprune`, Compose `dc*` |
| `podman` | `pd`, `pdps`, `pdlogf`, `pdsh`, `pdrun`, `pdprune`, Compose `pdc*` |
| `k8s` | `k`, `kgp`, `klf`, `kctx`, `kuse`, `knamespace`, `kpf`, `kdebug`, `kbad`, `kimages`, `ksecret`, `ksh`, `krun`, Helm `hm*` |
| `admin` | `logins`, `reboots`, `userinfo`, `failedlogins`, `svc`, `svcr`, `svcstop`, `enabled`, `bigfiles`, `deleted`, `kmsg`, `oom` |
| `ops` | `retry`, `every`, `tunnel`, `certexp`, `certfile`, `dnscheck`, `sockets`, `crons`, `logsize` |
| `infra` | Terraform `tf*` (`tfpo`/`tfao` saved plans), OpenTofu `tofu*`, Ansible `ap*` |
| `net` | `myip`, `lanip`, `ports [N]`, `freeport N`, `conns`, `hosts`, `dns`, `curlh`, `curlj` |
| `system` | `please`, `psmem`, `pscpu`, `psgrep`, systemd `sc`/`jc`, ufw `ufws`/`ufwa`/`ufwd`, apt/dnf/pacman/apk/brew, macOS, clipboard |
| `dev` | npm/pnpm/bun, pm2, `py`, `venv`, `serve`, Go, `cargo-*`, Maven/Gradle, `tlscheck` |
| `api` | `hget`/`hpost`/`hput`/`hpatch`/`hdelete`, `timing`, `watchurl`, `jwt`, `hexkey`, `selfcert`, `waitport`, `jl` |
| `db` | PostgreSQL `pg*`, MySQL `my*`, Redis `r*`, `mongol` |
| `nginx` | `ngt`, `ngr`, `ngrestart`, `ngs`, `nge`, `nga` (test before reload) |
| `remote` | `sshgen`, `sshcopy`, `sshkeys`, tmux `tl`/`ta`/`tn`/`tk` |
| `util` | `genpass`, `newuuid`, `epoch`, `fromepoch`, `b64`/`b64d`, `urlenc`/`urldec`, `httpcode`, `digs`, `topcmds`, `sysinfo`, `pk` |
| `dotenv` | `envset KEY=VAL` (insert or update), `envget`, `envdel`, `envls` |
| `cloud` | `awswho`, `azwho`, `gcwho` (read-only) |
| `tools` | `lg`, `ldk`, `rgf`, `fd`/`bat` shims |
| `modern` (opt-in) | `ls`→eza, `cat`→bat, `top`→btop, zoxide |
| `dangerous` (opt-in) | `docker-rm-stopped`, `docker-prune-all` with typed confirmation |

## Rules

- Tool modules load only when the tool is installed.
- Standard commands (`cp`, `mv`, `rm`, `cat`, `top`, `ping`) are not replaced by default.
- Destructive actions show targets and ask first; bulk deletes are opt-in and need a typed phrase.
- No implicit `sudo` outside package and power commands; no `-y` on upgrades.
- One meaning per name (`h` = history, Helm = `hm`).

## Development

```sh
./tests/run.sh             # every test under bash and zsh
python3 tools/gendocs.py   # regenerate docs/ from module comments
```

Doc conventions in module files: `# == Section`, and `# name ARGS — description` above each function.
