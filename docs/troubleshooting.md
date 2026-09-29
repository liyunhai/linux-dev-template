# Troubleshooting

## Confirm the detected OS and profile

Preview detection without changing the system:

```bash
./bootstrap.sh --dry-run
```

Ubuntu guests report platform `wsl` or `orbstack` and profile `cli`.
Fedora reports `native`; Workstation defaults to `desktop`, Server to `cli`.
The output also lists the package manager and per-module package plan.
Preview optional services with:

```bash
./bootstrap.sh --with postgres,nginx --dry-run
```

## WSL: systemd not active
Check:

```bash
ps -p 1 -o comm=
```

Expected: `systemd`

If not:
1. verify `/etc/wsl.conf` contains `systemd=true`
2. run `wsl --shutdown` from Windows
3. reopen the distro

## Unsupported environment or old profile

Native Fedora installations using DNF and Ubuntu in WSL/OrbStack are accepted.
Other hosts, including Fedora Atomic systems, exit before installing anything.
`--dry-run` reports the detected OS/platform and the support error.

Use `--profile cli` instead of the removed `server` profile. `desktop` is for
native Fedora; select `cli` inside WSL/OrbStack.
Add local services explicitly with `--with postgres,nginx`.

## nvm not found after install
Reload shell or source your shell config:

```bash
source ~/.zshrc
```

If `~/.zshrc` was created by Oh My Zsh before this template was installed, back
it up and explicitly install the project configuration:

```bash
./scripts/common/10-shell.sh --install-zshrc-template
exec zsh -l
```

## uv installed but not on PATH
Ensure `~/.local/bin` is on PATH.

## Yazi icons are missing or terminal text is widely spaced

On native Fedora, repair the local font with
`./scripts/common/12-nerd-font.sh --force`. For WSL/OrbStack, install or repair
the font on the Windows or macOS terminal host. In the
terminal profile, select `JetBrainsMono Nerd Font` and fully close and reopen
the terminal. Installing a font inside the guest will not update the host
terminal font.

## Wayland clipboard tools are missing

On native Fedora, use `./scripts/common/13-clipboard.sh` or enable the
`clipboard` module. `wl-copy` and `wl-paste` require a Wayland session to use
the desktop clipboard. Installation checks only their presence and does not
replace the clipboard contents or change compositor settings.

## Alacritty or Ghostty configuration module stops before installation

These optional modules configure existing terminal programs on native Fedora.
Install the terminal separately, then run `12-nerd-font.sh` before selecting
`14-alacritty.sh` or `14-ghostty.sh`. Existing configuration is backed up before
replacement. Applying a template resets its font size to 14 pt; edit the target
configuration afterwards for a different size.

An optional DMS theme import uses the terminal's own configuration directory.
Missing theme files fall back to terminal defaults. If a theme is present but
invalid, inspect the external theme file or remove its import from the terminal
configuration. Reopen the terminal to inspect the resulting appearance.

## Fedora PostgreSQL initialization fails

The optional PostgreSQL module initializes a new data directory using the
distribution's `postgresql-setup` command. An existing `PG_VERSION` skips
initialization. A nonempty directory without it is rejected for manual
inspection. The data path is read from `postgresql.service`; inspect customized
service settings if the installer cannot determine it.

## OpenVPN helper credentials need to be changed

Replace the keyring entries interactively:

```bash
vpn setup
```

Remove the saved profile and credentials completely with `vpn forget`. If the
keyring is locked, unlock it in the same session and retry `vpn-up`. The helper
requires a Secret Service keyring accessible from the guest; see
[OpenVPN helper notes](openvpn-linux.md).
