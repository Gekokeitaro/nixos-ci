# AGENTS.md — nixos-n8n-runner

Context guide for LLM agents working on the `nixos-n8n-runner` host.

## Purpose

Runs n8n task runners as an OCI container. Each runner connects to the
`nixos-n8n` broker and executes individual tasks, then shuts down after
an inactivity timeout (15s by default).

## Services & ports

| Service | Port | Notes |
|---|---|---|
| n8n-task-runners (OCI) | 20128 | `docker.io/n8nio/runners:stable` |

## Dependencies

- `nixos-n8n` broker at `http://192.168.18.22:5678` (runner connects here).
- Auth token shared with `nixos-n8n` (see Secrets).

## Secrets

sops-nix with `age.keyFile = "/home/nixos-n8n-runner/.config/sops/age/keys.txt"`:
- `n8n_runner_auth_token` — `sopsFile = ./secrets/auth-env.yaml`, mode `0444`.
- Injected into the container via `environmentFiles` (n8n expects
  `N8N_RUNNERS_AUTH_TOKEN` as an env var).

## Special config

- `N8N_RUNNERS_AUTO_SHUTDOWN_TIMEOUT = "15"` — runners stop 15s after task
  completion; `0` disables auto-shutdown.
- `N8N_RUNNERS_TASK_BROKER_URI = "http://192.168.18.22:5678"` — must match
  `nixos-n8n`'s runner broker port.
- Port `20128` is also exposed (container default).
- User `nixos-n8n-runner` with `extraGroups = ["wheel"]`, `jq` available.

## Constraints

- Unprivileged LXC.
- The auth token must match in both `nixos-n8n` (secret) and
  `nixos-n8n-runner` (secret).
- If `nixos-n8n` changes its broker listen address/port, update
  `N8N_RUNNERS_TASK_BROKER_URI` here.

## Modification guide

- To change auto-shutdown timeout: edit `N8N_RUNNERS_AUTO_SHUTDOWN_TIMEOUT`
  in the OCI env. `"0"` keeps runners alive indefinitely.
- To rotate the auth token: update `./secrets/auth-env.yaml` with sops and
  `hosts/nixos-n8n/secrets.yaml` on the n8n host, then re-apply both.