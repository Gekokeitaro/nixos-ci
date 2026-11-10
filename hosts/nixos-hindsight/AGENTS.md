# AGENTS.md — nixos-hindsight

Context guide for LLM agents working on the `nixos-hindsight` host.

## Purpose

Runs [Hindsight](https://github.com/vectorize-io/hindsight) as an OCI
container — an AI-powered data platform with built-in vector search.
Uses OmniRoute as its LLM provider and PostgreSQL (via `nixos-postgresql`)
as its backend database.

## Services & ports

| Service | Port | Notes |
|---|---|---|
| Hindsight (OCI) | 8888, 9999 | `ghcr.io/vectorize-io/hindsight:latest` |

## Dependencies

- `nixos-omniroute` at the endpoint listed in [INFRA.md](../../INFRA.md) -
  LLM provider (OpenAI-compatible endpoint).
- `nixos-postgresql` at the address/port listed in [INFRA.md](../../INFRA.md)
  - DB `hindsight`, user `hindsight`.
- OmniRoute model: `free-models` (set in OCI env).

## Secrets

sops-nix with `age.keyFile = "/home/nixos-hindsight/.config/sops/age/keys.txt"`:
- `hindsight-env` — `sopsFile = ./secrets/hindsight-env.env`,
  format `dotenv`, mode `0444`. Injected via `environmentFiles`.

## Special config

- OCI env (non-secret):
  - `HINDSIGHT_API_LLM_PROVIDER = "openai"`
  - `HINDSIGHT_API_LLM_BASE_URL = "http://192.168.18.32:20128/v1"`
  - `HINDSIGHT_API_LLM_MODEL = "free-models"`
- Additional secrets (API keys, etc.) come from the `.env` file via sops.
- `networking.hostName = "nixos-hindsight"`.
- `networking.firewall.allowedTCPPorts = [8888 9999]`.
- User `nixos-hindsight` with `extraGroups = ["wheel"]`.

## Constraints

- Unprivileged LXC.
- The DB password is shared with `nixos-postgresql` in
  `common/secrets/postgresql-shared.yaml`; rotate both together.
- Database connection details are supplied through the sops `hindsight-env`
  file; the values in `configuration.nix` cover only the LLM provider.
- The OmniRoute model id can change when the gateway is reconfigured; keep
  `HINDSIGHT_API_LLM_MODEL` aligned with a model actually served there.

## Modification guide

- To change the LLM model: update `HINDSIGHT_API_LLM_MODEL` in the OCI env
  (must match a model served by OmniRoute).
- To change the LLM endpoint: update `HINDSIGHT_API_LLM_BASE_URL` if
  OmniRoute moves.
- To add extra env vars (non-secret): add to the `environment` attrset;
  for secrets: add to `hindsight-env.env` (sops format `dotenv`) and
  ensure the key is added to `environmentFiles`.