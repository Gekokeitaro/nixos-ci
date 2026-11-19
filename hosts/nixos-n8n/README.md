# nixos-n8n

n8n workflow automation platform as an OCI container with an external
PostgreSQL backend and external task runners.

## Build

```bash
nixos-rebuild build-image --image-variant lxc --flake .#nixos-n8n
```

## Exposed ports

| Service | Port |
|---|---|
| n8n UI & API | 5678 |
| n8n task broker | 5679 |

Both are in `networking.firewall.allowedTCPPorts`. `5678` is n8n's own HTTP
port; `5679` is the task broker that external runners connect to in queue mode.
The runner URI currently uses `5678`.

## Dependencies

- PostgreSQL at the address/port listed in [INFRA.md](../../INFRA.md)
  (`nixos-postgresql` host, DB `n8n`).
- Task runners on `nixos-n8n-runner` connect back to the broker at the URI
  listed in [INFRA.md](../../INFRA.md).

## Secrets

- `n8n_db_password` — `common/secrets/postgresql-shared.yaml`
- `n8n_runner_auth_token` — shared with `nixos-n8n-runner`

sops-nix injects them into the container as `*_FILE` env vars (bind-mounted
at `/run/secrets/…`).

## First boot

1. Make sure `nixos-postgresql` is up and the `n8n` database exists with
   its password set (the `nixos-postgresql` one-shot service handles this).
2. Import the tarball as template in Proxmox, create and start the LXC
   (2 CPU, 2–4 GB RAM, 20 GB disk).
3. Open `http://<IP>:5678` — initial n8n setup wizard.
4. Create the admin user.
5. Deploy `nixos-n8n-runner` to bring up task runners on demand.

## SSH

```bash
ssh nixos-n8n@<IP>
```

## Apply changes

Remote:

```bash
nixos-rebuild switch --flake .#nixos-n8n --target-host <user>@<ip> --elevate=sudo
```

Inside the container:

```bash
sudo nixos-rebuild switch --flake .#nixos-n8n
```

## Notes

- The external runner URI is the broker URI listed in
  [INFRA.md](../../INFRA.md). The broker is `5679`; the runner currently points
  at `5678`.
- The database credentials live in sops and are mounted at `/run/secrets/…`.
