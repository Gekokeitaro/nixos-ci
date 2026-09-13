# AGENTS.md — nixos-ci

Context guide for LLM agents working on the `nixos-ci` host.

## Purpose

Development machine for building and updating LXC images. Also runs a Forgejo
runner (Podman) that connects to the `nixos-forgejo` instance for CI/CD.

## Services & ports

| Service | Port | Notes |
|---|---|---|
| forgejo-runner | — | Podman-backed runner (`services.forgejo-runner.instances.nixos-runner`) |

## Dependencies

- `nixos-forgejo` at `http://192.168.18.31:3000/` (runner registration).
- Runner UUID: `48ffc057-ff70-4b49-a19d-2848045fa023` (hardcoded).
- `virtualisation.podman.enable = true` — runner uses the `docker` label.

## Secrets

sops-nix with `defaultSopsFile = ./secrets.yaml`:
- `forgejo-runner-token` — token for connecting the runner to Forgejo.
- Age key: `/home/nixos-ci/.config/sops/age/keys.txt`.

## Special config

- User `nixos-ci` with `extraGroups = ["wheel"]`, SSH key (PopOS OCT 2024).
- `nix.settings.trusted-users = ["nixos-ci"]` + experimental features.
- Runner labels: `["docker"]`; token wired via
  `config.sops.secrets.forgejo-runner-token.path`.

## Constraints

- Unprivileged LXC (no privileged features).
- SSH keys must be present in `configuration.nix` before building the image
  or remote deployment will fail.
- The runner depends on `nixos-forgejo`; if Forgejo moves IP/port, update
  the `settings.server.connections.nixos-forgejo.url` here.

## Modification guide

- To rotate the runner token: regenerate in Forgejo UI, update
  `hosts/nixos-ci/secrets.yaml` with sops, re-apply.
- To add a runner label or runtime, edit
  `services.forgejo-runner.instances.nixos-runner.settings`.