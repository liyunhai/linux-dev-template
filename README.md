# Ubuntu Dev Template

A development template for Ubuntu running in:

- Windows 11 + WSL 2
- macOS + OrbStack Ubuntu machines

This repository provides:

- install scripts
- dotfiles
- sample nginx/project templates
- verification scripts

## Design goals

1. Keep the **Ubuntu userland** as similar as possible across WSL and OrbStack.
2. Keep **host-specific integration** outside Ubuntu where possible.
3. Prefer **simple, official installation paths** over clever but brittle ones.
4. Make scripts **idempotent** and easy to read/modify.

## High-level choices

- Shell: zsh + Oh My Zsh + Powerlevel10k
- Terminal host font: JetBrainsMono Nerd Font
- Terminal workspaces: tmux + Zellij + Herdr
- Terminal file manager: Yazi (latest stable release)
- Python: system python + venv + pipx + uv
- Node.js: nvm + latest LTS + pnpm
- Database clients: PostgreSQL, MySQL, Redis, and SQLite
- Optional local services: PostgreSQL and nginx
- Workspace root: `~/workspace`

## Installation profiles

The bootstrapper reads `/etc/os-release` and detects WSL or OrbStack. Only
Ubuntu in these two environments is currently accepted. Fedora support is
planned for a subsequent change; an unsupported host is detected and rejected
before any installation, including during a dry run.

The default `cli` profile installs the shared terminal development tools.
PostgreSQL and nginx are opt-in. The login shell changes only when
`--set-default-shell` is provided.

Run the detected default from the repository root:

```bash
./bootstrap.sh
```

Choose a profile or customize its modules:

```bash
./bootstrap.sh --profile cli
./bootstrap.sh --with postgres,nginx
./bootstrap.sh --skip herdr
./bootstrap.sh --set-default-shell
```

Available modules are `base`, `shell`, `tmux`, `zellij`, `herdr`,
`yazi`, `direnv`, `python`, `node`, `db-clients`, `postgres`, `nginx`,
and `devtools`.

The previous `server` and `desktop` profiles have been removed. Use `cli` and
select optional services with `--with postgres,nginx`.

Preview environment detection, module selection, script order, and the final
verification command without changing the system:

```bash
./bootstrap.sh --dry-run
./bootstrap.sh --with postgres,nginx --skip herdr --dry-run
```

Dry runs do not invoke sudo, install packages, download tools, modify user
configuration, or start services. They print the scripts that would execute;
installed-tool checks run only during a real installation.

On WSL without systemd, the first run writes `/etc/wsl.conf` and stops. Run
`wsl --shutdown` from Windows, reopen Ubuntu, and run `./bootstrap.sh` again.

## Individual installation

`00-base.sh` is the required foundation. Install the shell layer if wanted:

```bash
./scripts/common/00-base.sh
./scripts/common/10-shell.sh
```

Then run the modules you want. Every module remains a separate install script:

```text
scripts/common/15-tmux.sh
scripts/common/16-zellij.sh
scripts/common/17-herdr.sh
scripts/common/18-yazi.sh
scripts/common/19-openvpn-helper.sh          # optional OpenVPN 3 shortcuts
scripts/common/20-direnv.sh
scripts/common/30-python.sh
scripts/common/40-node.sh
scripts/common/50-db-clients.sh
scripts/common/60-postgres.sh
scripts/common/70-nginx.sh
scripts/wsl/00-wsl-preflight.sh           # WSL only
scripts/wsl/01-write-wslconf.sh           # WSL only
scripts/common/80-devtools.sh
scripts/common/90-verify.sh
```

The terminal tools can coexist. They are not configured to start or nest one
another automatically:

- tmux: established terminal multiplexer with TPM plugins
- Zellij: modern general-purpose terminal workspace
- Herdr: terminal workspace focused on coding-agent workflows
- Yazi: terminal file manager

Zellij, Herdr, and Yazi install their latest stable release to `~/.local/bin`.
Release checksums are verified before installation. Existing user configuration
is backed up before the template configuration is installed.

The shell template adds `~/.local/bin` and `~/bin` to interactive zsh sessions
and loads nvm from `~/.nvm`. On an existing installation, explicitly back up and
replace `~/.zshrc` with the project template by running:

```bash
./scripts/common/10-shell.sh --install-zshrc-template
```

Install and select `JetBrainsMono Nerd Font` in the terminal on Windows or
macOS, then fully reopen the terminal. The standalone font installer and check
are retained for future desktop support and are not part of the `cli` profile.

For an existing OpenVPN 3 Linux installation, the optional helper provides
`vpn-up`, `vpn-down`, `vpn-status`, and `vpn-restart`. Run `vpn setup` once;
credentials are stored in a Secret Service keyring and are never written to
the repository or a plaintext credentials file. The helper requires an
available, unlocked keyring in the guest session; see [OpenVPN helper notes](docs/openvpn-linux.md).

The proxy helper is not an installer. Evaluate its output in the current shell:

```bash
eval "$(python3 scripts/common/99-proxy-switch.py home)"
eval "$(python3 scripts/common/99-proxy-switch.py off)"
```

## Important notes

- **Fonts are installed on the terminal host OS**, not inside WSL or an
  OrbStack guest.
- On WSL, keep active projects under the Linux filesystem, e.g. `~/workspace`, not primarily under `/mnt/c/...`.
- On OrbStack, keep Ubuntu-side paths and shell workflows aligned with WSL.

## Reference docs

These scripts follow the official docs as closely as practical:

- WSL systemd and config: https://learn.microsoft.com/en-us/windows/wsl/systemd
- WSL advanced config: https://learn.microsoft.com/en-us/windows/wsl/wsl-config
- OrbStack machines: https://docs.orbstack.dev/machines/
- OrbStack machine CLI: https://docs.orbstack.dev/machines/commands
- Ubuntu nginx install/config: https://ubuntu.com/server/docs/how-to/web-services/install-nginx/
- uv installation: https://docs.astral.sh/uv/getting-started/installation/
- pre-commit: https://pre-commit.com/
- PostgreSQL on Ubuntu: https://www.postgresql.org/download/linux/ubuntu/
- Node.js download page (nvm guidance): https://nodejs.org/en/download
- Zellij installation: https://zellij.dev/documentation/installation.html
- Herdr installation: https://herdr.dev/docs/install/
- Yazi installation: https://yazi-rs.github.io/docs/installation

## Development checks

Run the environment and execution-plan tests without installing packages.
They simulate WSL and OrbStack, so they can also run on the current Fedora host:

```bash
./tests/test-bootstrap.sh
```
