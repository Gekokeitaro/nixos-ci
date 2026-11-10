# nixos-forgejo

Self-hosted Git forge (Forgejo, a Gitea fork) with SQLite backend and Actions
enabled. Designed for personal use; it coordinates the runners hosted on
`nixos-ci`.

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
2. Open `http://<IP>:3000` in a browser - the Forgejo setup wizard appears.
   The port is listed in [INFRA.md](../../INFRA.md).
3. Create the administrator user via the UI. Public registration is already
   disabled in the configuration; use the wizard or `forgejo-admin` for
   additional users.
4. Register the runners from `nixos-ci` (see that host's README).

## CI/CD

Actions are enabled globally. The deployment workflow currently lives in
`nixos-ci/.forgejo/workflows/deploy-llamaswap-rocm.yml` and uses two runners:

| Runner | Label | Purpose |
|---|---|---|
| `ci` | `host:host` | `nixos-rebuild` + SSH deployment |
| `nixos-runner` | `docker` | Containerized jobs |

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
- **Registration**: closed (`DISABLE_REGISTRATION = true`).
- **Domain / proxy**: `DOMAIN` and `ROOT_URL` use the Forgejo address listed in
  [INFRA.md](../../INFRA.md); change them together with the runner URLs on
  `nixos-ci` if a domain or HTTPS reverse proxy is added.
