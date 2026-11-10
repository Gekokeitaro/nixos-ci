# nixos-ci

Development machine for building and updating LXC images. It also runs two
Forgejo runners:

| Runner | Label | Purpose |
|---|---|---|
| `ci` | `host:host` | Deployment jobs with `nixos-rebuild` and SSH |
| `nixos-runner` | `docker` | Containerized jobs through Podman |

## Build

```bash
nixos-rebuild build-image --image-variant lxc --flake .#nixos-ci
```

## Exposed ports

No TCP ports opened. Both runners connect outbound to `nixos-forgejo`
(addresses and ports in [INFRA.md](../../INFRA.md)).

## First boot

1. Import the tarball as LXC template in Proxmox and create the container.
2. Verify Podman is available: `podman version`.
3. Confirm both runners are active:

   ```bash
   systemctl status forgejo-runner-ci.service
   systemctl status forgejo-runner-nixos-runner.service
   ```

4. Check the Forgejo dashboard (see [INFRA.md](../../INFRA.md) for its address)
   — both runners should appear under **Actions → Runners**.

## Automatic deployment

The workflow `.forgejo/workflows/deploy-llamaswap-rocm.yml` runs on the `ci`
runner:

- push to `main` → `nixos-rebuild switch` against `nixos-llamaswap-rocm`;
- push to `llamaswap-rocm` → `nixos-rebuild test` (build only).

The target is the SSH alias `nixos-llamaswap-rocm` → its address is in
[INFRA.md](../../INFRA.md). The
deploy key is the sops secret `deploy-key`, loaded by systemd as a credential.

> [!WARNING]
> Pushing to `main` deploys the ROCm host. Do not push unfinished configuration.

## Secrets

Managed with sops-nix in `./secrets.yaml`:

- `forgejo-runner-token` — shared by both runner instances.
- `deploy-key` — private key used by the deployment workflow.

Rotate a token:

1. Regenerate it in the Forgejo UI.
2. Update `hosts/nixos-ci/secrets.yaml` with `sops edit`.
3. Re-apply: `nixos-rebuild switch --flake .#nixos-ci`.

## SSH

```bash
ssh nixos-ci@<IP>
```

## Apply changes

Remote:

```bash
nixos-rebuild switch --flake .#nixos-ci --target-host <user>@<ip> --elevate=sudo
```

Inside the container:

```bash
sudo nixos-rebuild switch --flake .#nixos-ci
```
