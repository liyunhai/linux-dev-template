# Architecture

## Layered model

### L0 Host / virtualization
- Ubuntu in WSL 2 on Windows 11 or OrbStack on macOS
- systemd enabled where appropriate

### L1 Base packages
Common tools used by everything else:
- build-essential, git, curl, gnupg, unzip, jq, tmux, ripgrep, fd, etc.

### L2 Shell / terminal UX
- zsh
- Oh My Zsh
- Powerlevel10k
- JetBrainsMono Nerd Font on the terminal host OS
- zsh plugins
- tmux
- Zellij
- Herdr
- Yazi
- host-side Nerd Font configuration

### L3 Environment management
- direnv for per-project env activation
- uv for Python workflows
- nvm + pnpm for Node.js workflows

### L4 Language runtimes
- Python: system python + venv + pipx + uv
- Node.js: nvm + current LTS node

### L5 Data + web services
- PostgreSQL and nginx as optional local services
- Shared database client tools

### L6 Dev quality / tooling
- pre-commit
- shellcheck
- yamllint
- shfmt
- GitHub CLI

### L7 Template assets
- dotfiles
- service configs
- verification scripts

## Profiles and platform detection

`bootstrap.sh` separates the OS, runtime platform, and install profile:

- OS and platform jointly control compatibility: Ubuntu in WSL or OrbStack is
  accepted; other environments are rejected before installation.
- Platform controls WSL and OrbStack integration. Detection can also report
  `native`, which is currently unsupported by the bootstrapper.
- The `cli` profile selects shared terminal development modules. PostgreSQL
  and nginx are opt-in through `--with`.
- `--dry-run` reports detection and prints the execution plan without running
  installers or installed-tool checks.

The standalone Nerd Font installer and check remain as shared building blocks
for future desktop support. Fonts for WSL and OrbStack belong on the terminal
host OS.

Profiles only select shared modules. Distribution-specific scripts should be
added only when behavior genuinely cannot be expressed by the helpers under
`scripts/lib`.
