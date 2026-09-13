# AGENTS.md — nixos-postgresql

Context guide for LLM agents working on the `nixos-postgresql` host.

## Purpose

Central PostgreSQL database serving `nixos-n8n` and `nixos-hindsight`.
Includes pgvector extension for vector similarity search (used by Hindsight).

## Services & ports

| Service | Port | Notes |
|---|---|---|
| PostgreSQL | 5432 | `services.postgresql.enableTCPIP = true`, `networking.firewall.allowedTCPPorts = [5432]` |

## Dependencies

- Client hosts connect over the LAN: `n8n` from `192.168.18.22/24`,
  `hindsight` from `192.168.18.19/24` (both `scram-sha-256` auth).
- Databases: `n8n` (owner `n8n`), `hindsight` (owner `hindsight`).
- `pgvector` extension enabled on `hindsight` DB via `one-shot-config` service.

## Secrets

sops-nix with `age.keyFile = "/home/nixos-postgresql/.config/sops/age/keys.txt"`:
- `n8n_db_password` — `sopsFile = ../../common/secrets/postgresql-shared.yaml`,
  mode `0444`.
- `hindsight_db_password` — same source, mode `0444`.

## Special config

- `authentication` list (via `pkgs.lib.mkOverride 10`): local `trust`,
  remote per-host `scram-sha-256`. Host IPs are hardcoded.
- `one-shot-config` systemd service (Type=oneshot): reads passwords from sops
  secrets, runs `ALTER ROLE … WITH PASSWORD` statements, and installs the
  `vector` extension on the `hindsight` database.
- `local all all trust` — passwordless local access (pg_hba.conf override).

## Constraints

- Unprivileged LXC; no host PostgreSQL filesystem sharing needed.
- `pgvector` is installed on `hindsight` only; `n8n` DB has no extensions.
- Password rotation requires: update `common/secrets/postgresql-shared.yaml`
  with sops, then re-apply both `nixos-postgresql` and the affected client
  (`nixos-n8n` or `nixos-hindsight`).
- WARNING: the `one-shot-config` service re-runs `ALTER ROLE` on every boot
  — this is intentional to keep passwords in sync with sops.

## Modification guide

### Adding a new database

1. Add the DB name to `services.postgresql.ensureDatabases`.
2. Add an entry to `ensureUsers` with `ensureDBOwnership = true`.
3. Add an `authentication` rule for the client host/subnet.
4. If passwords are managed by sops, add a new secret and an `ALTER ROLE`
   statement to `one-shot-config`.
5. Add `networking.firewall.allowedTCPPorts` if the new port differs.