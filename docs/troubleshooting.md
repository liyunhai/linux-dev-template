# Troubleshooting

## Confirm the detected OS and profile

Preview detection without changing the system:

```bash
./bootstrap.sh --dry-run
```

Supported hosts report Ubuntu, platform `wsl` or `orbstack`, and profile `cli`.
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

Only Ubuntu in WSL 2 or OrbStack is currently accepted. An unsupported host,
including Fedora until its adaptation is complete, exits before installing
anything. `--dry-run` reports the detected OS/platform and the support error.

Use `--profile cli` instead of the removed `server` or `desktop` profiles.
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

Install or repair the font on the Windows or macOS terminal host. In the
terminal profile, select `JetBrainsMono Nerd Font` and fully close and reopen
the terminal. Installing a font inside the guest will not update the host
terminal font.

## OpenVPN helper credentials need to be changed

Replace the keyring entries interactively:

```bash
vpn setup
```

Remove the saved profile and credentials completely with `vpn forget`. If the
keyring is locked, unlock it in the same session and retry `vpn-up`. The helper
requires a Secret Service keyring accessible from the guest; see
[OpenVPN helper notes](openvpn-linux.md).
