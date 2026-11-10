# AGENTS.md — nixos-ci

Context guide for LLM agents working on the `nixos-ci` host.

## Purpose

Development machine for building and updating LXC images. It also runs two
Forgejo runner instances:

- `ci` — label `host:host`; executes the deployment workflow with
  `nixos-rebuild` and SSH.
- `nixos-runner` — label `docker`; executes containerized jobs through Podman.

## Services & ports

| Service | Port | Notes |
|---|---|---|
| `forgejo-runner-ci` | — | Host runner; `PATH` includes `nixos-rebuild` and `openssh`; loads the `deploykey` credential |
| `forgejo-runner-nixos-runner` | — | Podman runner; label `docker` |

No inbound TCP ports. Both runners connect outbound to `nixos-forgejo`.
Addresses and ports are in [INFRA.md](../../INFRA.md).

## Dependencies

- `nixos-forgejo` for runner registration and Actions.
- Podman (`virtualisation.podman.enable = true`) for the `docker` runner.
- SSH alias `nixos-llamaswap-rocm` points to the ROCm host (see
  [INFRA.md](../../INFRA.md)), used by the deployment workflow.
- The `deploy-runner` public key is authorized in
  `hosts/llamaswap-lxc/configuration.nix`.

## Secrets

sops-nix with `defaultSopsFile = ./secrets.yaml` and
`age.keyFile = "/home/nixos-ci/.config/sops/age/keys.txt"`:

- `forgejo-runner-token` — shared by both runner instances.
- `deploy-key` — mode `0400`; exposed to `forgejo-runner-ci` as the
  `deploykey` systemd credential.

## Special config

- Runner `ci`: UUID `15ab8222-2f49-49a6-8969-828b64614dc3`, labels
  `["host:host"]`, service `forgejo-runner-ci`.
- Runner `nixos-runner`: UUID `48ffc057-ff70-4b49-a19d-2848045fa023`,
  labels `["docker"]`, connection `nixos-forgejo`, `runtimes.podman = true`.
- `programs.ssh.extraConfig` maps `nixos-llamaswap-rocm` to the ROCm host
  address (see [INFRA.md](../../INFRA.md)).
- User `nixos-ci` with `extraGroups = ["wheel"]` and three authorized keys
  (PopOS OCT 2024, ibuki, pablo.bugarin.camara@gmail.com).

## Deployment workflow

`.forgejo/workflows/deploy-llamaswap-rocm.yml` runs on the `ci` runner
(`runs-on: host`):

- Triggers: push to `main`, push to `llamaswap-rocm`, and manual dispatch.
- `main` → `nixos-rebuild switch --flake .#nixos-llamaswap-rocm`.
- `llamaswap-rocm` → `nixos-rebuild test` (builds without activating).
- The deploy key is read from
  `/run/credentials/forgejo-runner-ci.service/deploykey` and passed to Nix
  through `NIX_SSHOPTS`.

## Constraints

- A push to `main` deploys `nixos-llamaswap-rocm` to production. Do not push
  work-in-progress configuration to `main`.
- If `nixos-forgejo` moves, update both runner connection URLs:
  `settings.server.connections.nixos-forgejo.url` and
  `settings.server.connections.forgejo.url`.
- If the llama-swap host moves, update `programs.ssh.extraConfig` and the
  `HostName`; the workflow targets the alias, not an IP.
- The `ci` service fails without the `deploy-key` secret. Rotate it in sops,
  not in the workflow.
- Only `nixos-llamaswap-rocm` is automated. Other hosts are applied manually.

## Modification guide

### Rotate a runner token

1. Regenerate the token in the Forgejo UI.
2. Update `hosts/nixos-ci/secrets.yaml` with `sops edit`.
3. Re-apply `nixos-ci` (`nixos-rebuild switch --flake .#nixos-ci`).

### Rotate the deployment key

1. Generate a new key pair and authorize the public key in
   `hosts/llamaswap-lxc/configuration.nix` (and apply that host).
2. Put the private key in `hosts/nixos-ci/secrets.yaml` under `deploy-key`.
3. Re-apply `nixos-ci` so systemd refreshes the credential.

### Add a runner or label

Add a new `services.forgejo-runner.instances.<name>` entry, set its connection
UUID and token, and choose labels that match the workflows. Keep the `ci`
instance reserved for jobs that need the host and the deploy credential.
