# Fedora notes

## Editions and profiles

Fedora Workstation defaults to `desktop`, adding local fonts and Wayland
clipboard commands to the shared developer tools. Fedora Server defaults to
`cli`; a missing edition identifier also defaults to `cli`. An explicit
`--profile` overrides the default. Neither profile installs or configures a
desktop session. Existing niri/DMS setup is managed outside this repository.

The installer accepts native Fedora using DNF, without restricting the Fedora
version number. Its package mappings use standard Fedora repository names.
Fedora Atomic/rpm-ostree installations are outside this installation path.

## Package differences

Shared module scripts use `scripts/lib/packages.sh` for system dependencies.
Fedora's compiler packages replace Ubuntu's `build-essential`, Python's venv
support is provided by `python3`, and Yazi uses `7zip`. Database clients include
`psql`, `mysql`, `sqlite3`, and `valkey-cli` for Redis-compatible use. Valkey's
package contains server components, but the client module does not enable or
start the service.

Curl is requested through the `/usr/bin/curl` file dependency, allowing DNF
to keep an existing `curl` or `curl-minimal` provider.

## Optional services

PostgreSQL and nginx are installed only when selected, for example:

```bash
./bootstrap.sh --with postgres,nginx --dry-run
```

PostgreSQL uses Fedora's `postgresql-server` and `postgresql` packages. The
installer reads `PGDATA` from the systemd unit, initializes only a new/empty
data directory, and skips initialization when `PG_VERSION` already exists.
Unexpected existing files cause an error rather than reinitialization.
Service start failures are reported. Existing clusters are not upgraded by
this installer. See [PostgreSQL's Fedora installation instructions](https://www.postgresql.org/download/linux/redhat/).

nginx site examples are copied into `~/workspace/infra/nginx-templates` for
review. Activating a Fedora site uses `/etc/nginx/conf.d/<name>.conf`; Ubuntu
uses `sites-available` and `sites-enabled`. No sample site is activated
automatically. Use appropriate file permissions and SELinux labels when
choosing a document root; the default Fedora document root is
`/usr/share/nginx/html`.

The scripts use the distribution's default service configuration. Firewall
rules and SELinux policy require configuration for the particular site or
remote access being enabled.

## Optional terminal configuration

Use `--with alacritty,ghostty` to select user configuration for either or both
already-installed terminals. These modules follow `nerd-font` in the execution
order and require that font; Server users can select `--with nerd-font,alacritty`
with the `cli` profile when configuring an installed graphical terminal.

The templates use JetBrainsMono Nerd Font at 14 pt, roomier cell height and
padding, a blinking block cursor, and mouse hiding during typing. Optional
imports use existing DMS color files and tolerate their absence. Applying a
template backs up a different existing configuration before replacing it.
No terminal package, DMS theme, or compositor configuration is installed.

## Validation status

- Fedora 44 Workstation: actual OS/profile detection and read-only dry runs;
  mapped package availability checked against local DNF repository metadata.
- Fedora Workstation/Server version fixtures: default/explicit profiles,
  optional modules, and dry-run side effects tested with simulated environments.
- Ubuntu WSL/OrbStack: execution plans and APT dispatch tested with mocks.
- PostgreSQL initialization: new, existing, and incomplete data directories
  tested using temporary directories and mocked service/setup commands.
- Manual Fedora 44 validation: every default desktop module installed, including
  Node.js/npm/pnpm, database clients, and development tools. Alacritty/Ghostty
  configuration and Wayland clipboard round-trip passed. The complete selected
  module check finished with `[90-verify] all checks passed`.
- The revised `15-tmux.sh` dry run and automatic plugin workflow both passed
  manual validation. TPM and the configuration were retained on a rerun, and
  all declared plugins were found installed.
- The account login shell is now `/usr/bin/zsh`; the project `.zshrc` and
  Oh My Zsh environment are installed.
- Fedora's `shfmt` package formats shell input correctly, although
  `shfmt --version` prints no text on this machine.
- During the original base installation, DNF downgraded C++ runtime and fcitx5
  packages; an explicit upgrade from Fedora's official repositories restored
  them, and `dnf check --dependencies` found no issues afterward.

The optional PostgreSQL/nginx service modules and Ubuntu guest installation
remain to be validated before merging this branch.
