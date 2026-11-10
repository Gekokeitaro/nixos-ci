# AGENTS.md — nixos-forgejo

Context guide for LLM agents working on the `nixos-forgejo` host.

## Purpose

Self-hosted Git forge (Forgejo) with Actions enabled. Uses SQLite (no external
DB server), which is enough for personal use. Runs at the address and port
listed in [INFRA.md](../../INFRA.md).

## Services & ports

| Service | Port | Notes |
|---|---|---|
| Forgejo | 3000 | HTTP dashboard/API; `networking.firewall.allowedTCPPorts = [3000]`; Actions enabled |

## Dependencies

- SQLite database (no external service).
- `services.forgejo` NixOS module; the service runs as its own system user
  `forgejo`.
- Two runners registered from `nixos-ci`: `ci` (`host:host`) and
  `nixos-runner` (`docker`).

## Secrets

No sops-nix configuration. Runner tokens and the deployment key live in
`hosts/nixos-ci/secrets.yaml`.

## Special config

- `networking.hostName = "nixos-forgejo"`.
- `services.forgejo.settings.service.DISABLE_REGISTRATION = true` — public
  registration is closed.
- `services.forgejo.settings.actions.ENABLED = true` — Actions are active.
- `services.forgejo.settings.server`: HTTP port and address are in [INFRA.md](../../INFRA.md).
  `DOMAIN` and `ROOT_URL` must stay in sync with the actual address.
- User `nixos-forgejo` with `extraGroups = ["wheel"]` and three SSH keys
  (PopOS OCT 2024, NixOS-CI MAY 2026, pablo.bugarin.camara@gmail.com).
- `forgejo-admin` wrapper in `environment.systemPackages` runs the Forgejo CLI
  as the service user with the correct work path.
- CLI tools are declared in `environment.systemPackages` (not
  `users.users.<name>.packages`: that attribute only exists with home-manager).

## Constraints

- Unprivileged LXC.
- Passwordless sudo via `common` (wheel group).
- `nix.settings.trusted-users = ["nixos-forgejo"]` allows
  `nixos-rebuild --flake` inside the container.
- `DOMAIN` and `ROOT_URL` must stay in sync with the actual address; runner
  connection URLs on `nixos-ci` depend on it.

## Modification guide

### Create or manage users

Public registration is closed. Create users from the CLI:

```bash
forgejo-admin admin user create --username <name> --admin --email <email> --random-password
```

### Change the address or port

1. Update `DOMAIN`, `ROOT_URL`, and (if needed) `HTTP_PORT` here.
2. Update the two runner connection URLs in `hosts/nixos-ci`.
3. Re-apply both hosts.

### Add a runner

Configure it on the runner host (see `hosts/nixos-ci`), then confirm it appears
under **Actions → Runners**. Do not enable Actions per-repository manually if
the global switch is already on.
