# nixos-forgejo

Self-hosted Git forge (Forgejo, a Gitea fork) with SQLite backend. Designed
for personal use; can host CI/CD via runners (`nixos-ci`) when actions are
enabled.

## Build

```bash
nixos-rebuild build-image --image-variant lxc --flake .#nixos-forgejo
```

## Exposed ports

| Service | Port |
|---|---|
| Forgejo (HTTP) | 3000 |

## First boot

1. Import the tarball as template in Proxmox, create and start the LXC.
2. Open `http://<IP>:3000` in a browser — the Forgejo setup wizard appears.
3. Create the administrator user via the UI.
4. Once the admin account exists, close public registration:

   ```nix
   # in configuration.nix
   services.forgejo.settings.service.DISABLE_REGISTRATION = true;
   ```

   Then re-apply (see "Apply changes" below).

## SSH

```bash
ssh nixos-forgejo@<IP>
```

## Apply changes

Remote:

```bash
nixos-rebuild switch --flake .#nixos-forgejo --target-host <user>@<ip> --elevate=sudo
```

Inside the container:

```bash
sudo nixos-rebuild switch --flake .#nixos-forgejo
```

## Notes

- **Database**: SQLite (`services.forgejo.database.type = "sqlite3"`). No extra
  server process. For high-load production, migrate to PostgreSQL.
- **Enabling CI/CD actions**: add `services.forgejo.settings.actions.ENABLED = true`
  (requires a registered runner; see `hosts/nixos-ci`).
- **Domain / proxy**: `DOMAIN` and `ROOT_URL` currently use `0.0.0.0`. Change
  them to the real FQDN/IP when a domain or HTTPS reverse proxy is added.
