# WSL notes

## Why systemd matters
Optional local services such as PostgreSQL and nginx integrate better when systemd is enabled.

## Why `~/workspace`
Microsoft recommends storing Linux projects in the Linux filesystem for better performance with Linux tooling, instead of primarily using `/mnt/c/...`.

## Config split
- `/etc/wsl.conf`: distro-level behavior
- `%UserProfile%\\.wslconfig`: global WSL VM behavior

## Rebuild flow
After changing `/etc/wsl.conf` or `.wslconfig`, run from Windows:

```powershell
wsl --shutdown
```

Then start the distro again.
