# AGENTS.md — nixos-omniroute

Context guide for LLM agents working on the `nixos-omniroute` host.

## Purpose

Runs OmniRoute (AI gateway by Diego Souza) as an OCI container. Used as a
unified LLM routing layer by other services (e.g., `nixos-hindsight`).

## Services & ports

| Service | Port | Notes |
|---|---|---|
| OmniRoute (OCI) | 20128 | `docker.io/diegosouzapw/omniroute:latest` |

## Dependencies

- Persistent data on host: `/var/lib/omniroute:/app/data` (bind mount).

## Secrets

No sops-nix configuration. `OMNIROUTE_BOOTSTRAPPED = "true"` is set in
the OCI env (no secrets handled in Nix). Runtime secrets (e.g.,
`OMNIROUTE_WS_BRIDGE_SECRET`, `INITIAL_PASSWORD`) must be set outside
Nix after first boot if needed.

## Special config

- `PUID=1000`, `PGID=1000`, `TZ=Europe/Madrid`.
- `OMNIROUTE_BOOTSTRAPPED = "true"` — skips first-run wizard.
- `systemd.tmpfiles.rules` creates `/var/lib/omniroute` with `0750 1000 1000`.
- User `nixos-omniroute` with `extraGroups = ["wheel"]`.

## Constraints

- Unprivileged LXC.
- Data persistence depends on the bind mount `/var/lib/omniroute`; if the
  container is removed, data survives but must be reattached.
- WARNING: earlier documentation referenced a named volume `omniroute-data`
  — current setup uses a bind mount with `tmpfiles`.

## Modification guide

- No inline Nix logic; OCI config is the only NixOS surface.
- To change PUID/PGID: update the OCI env; the volume dir must match the
  new UID/GID owner (adjust the `tmpfiles` rule accordingly).