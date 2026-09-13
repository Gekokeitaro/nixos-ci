# AGENTS.md — nixos-forgejo

Context guide for LLM agents working on the `nixos-forgejo` host.

## Purpose

Self-hosted Git forge (Forgejo) with CI/CD capability. Uses SQLite (no
external DB server) — sufficient for personal use.

## Services & ports

| Service | Port | Notes |
|---|---|---|
| Forgejo | 3000 | HTTP dashboard, `networking.firewall.allowedTCPPorts = [3000]` |

## Dependencies

- SQLite database (no external service).
- `services.forgejo` NixOS module; service runs as its own system user `forgejo`.

## Secrets

No sops-nix configuration.

## Special config

- `networking.hostName = "nixos-forgejo"`.
- `services.forgejo.settings.service.DISABLE_REGISTRATION = false` — open
  registration. Set to `true` once the admin user is created.
- `services.forgejo.settings.server`: `HTTP_PORT = 3000`, `DOMAIN = "0.0.0.0"`,
  `ROOT_URL = "http://0.0.0.0:3000/"`. Change to real FQDN when a permanent
  domain/proxy is configured.
- User `nixos-forgejo` with `extraGroups = ["wheel"]`, SSH keys (PopOS + CI).
- CLI tools in `environment.systemPackages` (not `users.users.<name>.packages`:
  that module attribute only exists with home-manager).

## Constraints

- Unprivileged LXC.
- Passwordless sudo via `common` (wheel group).
- `nix.settings.trusted-users` includes `nixos-forgejo` for
  `nixos-rebuild --flake` inside the container.

## Modification guide

### Enable CI/CD actions

Add `services.forgejo.settings.actions.ENABLED = true` once a runner is
configured (see `nixos-ci` host).

### Close public registration

Set `services.forgejo.settings.service.DISABLE_REGISTRATION = true` after
creating the admin user via the UI wizard, then re-apply.