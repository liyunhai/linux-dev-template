# Installation inventory by script

`scripts/common/00-base.sh` is the shared prerequisite for the other installers.
The package names below are the packages explicitly requested by this project;
DNF and APT may add their own dependencies or weak dependencies. Fedora columns
apply to native Fedora, and Ubuntu columns apply to WSL or OrbStack Ubuntu.

| Script | Fedora packages | Ubuntu packages | Other installed items or changes |
|---|---|---|---|
| `00-base.sh` | `ca-certificates`, `/usr/bin/curl`, `wget`, `unzip`, `zip`, `jq`, `tree`, `ripgrep`, `fd-find`, `fzf`, `htop`, `git`, `make`, `tar`, `gcc`, `gcc-c++`, `glibc-devel`, `gnupg2`, `openssh-clients`, `pkgconf-pkg-config` | `ca-certificates`, `curl`, `wget`, `unzip`, `zip`, `jq`, `tree`, `ripgrep`, `fd-find`, `fzf`, `htop`, `git`, `make`, `tar`, `build-essential`, `gnupg`, `software-properties-common`, `openssh-client`, `pkg-config` | Creates `~/workspace/{apps,libs,infra,playground}`, `~/bin`, and `~/.local/bin`. Fedora uses the curl executable dependency to accept either `curl` or `curl-minimal`. |
| `10-shell.sh` | `zsh` | `zsh` | Installs Oh My Zsh, Powerlevel10k, zsh autosuggestions, syntax highlighting, and completions from Git; installs shell helper files and optionally the project `.zshrc`. `--set-default-shell` changes the login shell through `chsh`. Git, curl, and fzf come from `00-base.sh`. |
| `12-nerd-font.sh` | `fontconfig` if its commands are missing | Not supported in Ubuntu guests | Downloads and verifies JetBrainsMono Nerd Font, then installs Regular, Bold, Italic, and Bold Italic files under `~/.local/share/fonts`. |
| `13-clipboard.sh` | `wl-clipboard` | Not supported in Ubuntu guests | Provides `wl-copy` and `wl-paste`. |
| `14-alacritty.sh` | None | Not supported in Ubuntu guests | Installs the Alacritty configuration for an already installed terminal; requires the Nerd Font. |
| `14-ghostty.sh` | None | Not supported in Ubuntu guests | Installs the Ghostty configuration for an already installed terminal; requires the Nerd Font. |
| `15-tmux.sh` | `tmux` | `tmux`, `xclip`, `xsel` | Installs the tmux configuration, TPM, and its declared plugins: `tmux-sensible`, `tmux-yank`, `tmux-resurrect`, `tmux-continuum`, and `catppuccin/tmux`. Git comes from `00-base.sh`; Fedora Wayland clipboard tools come from `13-clipboard.sh`. |
| `16-zellij.sh` | None | None | Downloads and verifies the Zellij binary, then installs it and its configuration. |
| `17-herdr.sh` | None | None | Downloads and verifies the Herdr binary, then installs it and its configuration. |
| `18-yazi.sh` | `zoxide`, `file`, `poppler-utils`, `mediainfo`, `7zip` | `zoxide`, `file`, `poppler-utils`, `mediainfo`, `p7zip-full` | Downloads and verifies `yazi` and `ya`, then installs their configuration. fd, ripgrep, fzf, jq, curl, and unzip come from `00-base.sh`. |
| `19-openvpn-helper.sh` | `libsecret` if `secret-tool` is missing | `libsecret-tools` if `secret-tool` is missing | Installs the `vpn` helper and four command links. Requires an existing OpenVPN 3 installation; it does not install OpenVPN 3. |
| `20-direnv.sh` | `direnv` | `direnv` | Installs `direnv.toml` and adds the zsh hook only if absent. |
| `30-python.sh` | `python3`, `python3-pip`, `pipx` | `python3`, `python3-pip`, `pipx`, `python3-venv` | Installs pip configuration, uv via its official installer, and `ruff`, `black`, `pytest`, `pre-commit` through pipx. curl comes from `00-base.sh`. |
| `40-node.sh` | None | None | Uses base curl and Git to install nvm, the latest Node.js LTS and npm, then globally installs `pnpm`, `typescript`, `tsx`, `eslint`, `prettier`, `pm2`, and `npm-check-updates`. Its npm command allows only the `pnpm` and `esbuild` install scripts for that invocation. |
| `50-db-clients.sh` | `sqlite`, `postgresql`, `mysql`, `valkey` | `sqlite3`, `postgresql-client`, `mysql-client`, `redis-tools` | Installs command-line database tools. It does not enable or start services. |
| `60-postgres.sh` | `postgresql-server` | `postgresql` | Initializes the Fedora cluster when needed, then enables and starts PostgreSQL when systemd is available. The client is owned by `50-db-clients.sh`; the server package manager may also pull it as a dependency. |
| `70-nginx.sh` | `nginx` | `nginx` | Installs example configurations under `~/workspace/infra/nginx-templates`, validates nginx configuration, and enables and starts nginx when systemd is available. |
| `80-devtools.sh` | `yamllint`, `shfmt`, `gh`, `ShellCheck` | `yamllint`, `shfmt`, `gh`, `shellcheck` | Installs CLI quality tools. `pre-commit` is owned by `30-python.sh`. |
| `90-verify.sh` | None | None | Runs available checks for selected modules. It installs no applications or libraries. |

The optional PostgreSQL and nginx service modules are not part of either
default profile. Terminal configuration modules do not install the terminal
applications themselves. `niri` and DMS are outside this project's scope.
