# Architecture

## Layered model

### L0 Host / virtualization
- Ubuntu in WSL 2 on Windows 11 or OrbStack on macOS
- Native Fedora Workstation or Server with DNF
- systemd enabled where appropriate

### L1 Base packages
Common tools used by everything else:
- build-essential, git, curl, gnupg, unzip, jq, tmux, ripgrep, fd, etc.

### L2 Shell / terminal UX
- zsh
- Oh My Zsh
- Powerlevel10k
- JetBrainsMono Nerd Font on the terminal host OS
- Wayland clipboard commands on native Fedora desktops
- Optional Alacritty and Ghostty user configuration
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

- OS and platform jointly control compatibility: native Fedora with DNF and
  Ubuntu in WSL/OrbStack are accepted. OS detection also records version and
  edition, without a Fedora version allowlist.
- Platform controls WSL and OrbStack integration. Fedora uses `native`.
- Fedora Workstation defaults to `desktop`; Fedora Server and Ubuntu guests
  default to `cli`. PostgreSQL and nginx are opt-in through `--with`.
- `scripts/lib/packages.sh` maps module dependencies to distro package names
  and dispatches to DNF or APT. Individual module installers share this helper.
- `--dry-run` reports detection and prints the execution plan without running
  installers or installed-tool checks.

The desktop profile adds local Nerd Fonts and Wayland clipboard commands.
These modules are restricted to native Fedora. Fonts for WSL and OrbStack
belong on the terminal host OS. niri/DMS installation and configuration are
outside the project scope.

The optional `alacritty` and `ghostty` modules install terminal templates using
`scripts/lib/terminals.sh`. They require the terminal program and Nerd Font
to be installed first, use the shared configuration backup helper, and respect
`XDG_CONFIG_HOME`. They are restricted to native Fedora and install no packages.
Dry runs show the source, destination, and prerequisites. Existing DMS color
files are referenced through optional imports; the project does not manage them.

Profiles only select shared modules. Distribution-specific scripts should be
added only when behavior genuinely cannot be expressed by the helpers under
`scripts/lib`.
