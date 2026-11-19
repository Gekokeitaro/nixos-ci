# AGENTS.md — nixos-n8n

Context guide for LLM agents working on the `nixos-n8n` host.

## Purpose

Runs n8n (workflow automation platform) as an OCI container backed by an
external PostgreSQL, with external task runners (`nixos-n8n-runner`).

## Services & ports

| Service | Port | Notes |
|---|---|---|
| n8n (OCI) | 5678 (UI/API), 5679 (task broker) | `docker.io/n8nio/n8n:stable` |

## Dependencies

- `nixos-postgresql` at the address/port listed in [INFRA.md](../../INFRA.md)
  (DB `n8n`, user `n8n`).
- `nixos-n8n-runner` connects to the broker URI listed in [INFRA.md](../../INFRA.md).
- Named volume `n8n_data:/home/node/.n8n`.

## Secrets

sops-nix with `defaultSopsFile = ./secrets.yaml`:
- `n8n_db_password` — `sopsFile = ../../common/secrets/postgresql-shared.yaml`,
  mode `0444`.
- `n8n_runner_auth_token` — mode `0444`, shared with `nixos-n8n-runner`.
- Age key: `/home/nixos-n8n/.config/sops/age/keys.txt`.

## Special config

- OCI env: `DB_TYPE=postgresdb`, `DB_POSTGRESDB_HOST/PORT/USER`,
  `DB_POSTGRESDB_PASSWORD_FILE` (sops path), `N8N_RUNNERS_MODE=external`,
  `N8N_RUNNERS_AUTH_TOKEN_FILE` (sops path).
- Secrets mounted into the container via `volumes` as `/run/secrets/…`.
- `N8N_SECURE_COOKIE=false`, `GENERIC_TIMEZONE=Europe/Madrid`.
- `networking.firewall.allowedTCPPorts = [5678 5679]`.
- User `nixos-n8n` with `extraGroups = ["wheel"]`.

## Constraints

- Unprivileged LXC.
- The DB password is also stored in `common/secrets/postgresql-shared.yaml`
  (shared with `nixos-postgresql`); rotate it in both places.
- The task broker listens on `5679`; the runner URI currently points at `5678`,
  n8n's own HTTP port. The tree publishes both.

## Modification guide

- To change DB: update `DB_POSTGRESDB_*` env vars and the secret if needed.
- Runner auth token must match in `nixos-n8n` and `nixos-n8n-runner`.
- The broker port in `N8N_RUNNERS_TASK_BROKER_URI` on the runner must be `5679`,
  the task broker n8n exposes; the current runner config uses `5678`.

## Skills

Load the `caveman` skill at the start of every session (`skill` tool, id `caveman`).
