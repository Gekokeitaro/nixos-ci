# nixos-postgresql

Central PostgreSQL server for `nixos-n8n` and `nixos-hindsight`. Includes
pgvector for vector similarity search (Hindsight).

## Build

```bash
nixos-rebuild build-image --image-variant lxc --flake .#nixos-postgresql
```

## Exposed ports

| Service | Port |
|---|---|
| PostgreSQL | 5432 |

Allowed in `networking.firewall.allowedTCPPorts` and via `enableTCPIP = true`.

## Databases

| Database | Owner | Used by |
|---|---|---|
| `n8n` | `n8n` | `nixos-n8n` (`192.168.18.22/24`, scram-sha-256) |
| `hindsight` | `hindsight` | `nixos-hindsight` (`192.168.18.19/24`, scram-sha-256) |

The `hindsight` DB also has the `pgvector` extension installed.

## Secrets

Managed by sops-nix, both sourced from
`common/secrets/postgresql-shared.yaml`:
- `n8n_db_password`
- `hindsight_db_password`

A `one-shot-config` systemd service reads these secrets and runs
`ALTER ROLE … WITH PASSWORD` on every boot to keep passwords in sync.

## First boot

1. Import the tarball, create and start the LXC.
2. The one-shot service sets the passwords for `n8n` and `hindsight` roles
   from sops secrets and installs `pgvector` on the `hindsight` DB.
3. Confirm: `sudo -u postgres psql -d n8n -c "\dt"` should connect without
   error.
4. Start `nixos-n8n` and `nixos-hindsight` — they will connect to this host
   over the LAN.

## SSH

```bash
ssh nixos-postgresql@<IP>
```

## Apply changes

Remote:

```bash
nixos-rebuild switch --flake .#nixos-postgresql --target-host <user>@<ip> --elevate=sudo
```

Inside the container:

```bash
sudo nixos-rebuild switch --flake .#nixos-postgresql
```

## Password rotation

1. Update the password in `common/secrets/postgresql-shared.yaml` with sops.
2. Re-apply `nixos-postgresql` (the one-shot service writes the new password).
3. Update the same secret in the client host (e.g., `hosts/nixos-n8n/secrets.yaml`)
   and re-apply that host too.

## Adding a new database

1. Add to `services.postgresql.ensureDatabases`.
2. Add a matching entry to `ensureUsers` (`ensureDBOwnership = true`).
3. Add an `authentication` rule for the new client host/subnet.
4. If passwords are managed by sops: add a secret to `postgresql-shared.yaml`
   and an `ALTER ROLE` line to the `one-shot-config` script.
5. Apply the client host with the new DB credentials.
