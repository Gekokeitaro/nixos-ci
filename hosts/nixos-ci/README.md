# nixos-ci

Development machine for building and updating LXC images.
Also hosts a Forgejo runner (Podman) that connects to `nixos-forgejo` for CI/CD.

## Build

```bash
nixos-rebuild build-image --image-variant lxc --flake .#nixos-ci
```

## Exposed ports

No TCP ports opened. The Forgejo runner connects outbound to
`nixos-forgejo` at `http://192.168.18.31:3000/`.

## First boot

1. Import the tarball as LXC template in Proxmox and create the container.
2. Verify Podman is available: `podman version`.
3. Confirm the runner is active: `systemctl status forgejo-runner-nixos-runner.service`.
4. Check Forgejo dashboard (`http://192.168.18.31:3000/`) — the runner should
   appear under **Actions → Runners**.

## SSH

```bash
ssh nixos-ci@<IP>
```

## Secrets

The runner token is managed via sops-nix (`./secrets.yaml`) and injected as
`config.sops.secrets.forgejo-runner-token.path`. Rotate it via:

1. Regenerate the token in the Forgejo UI.
2. Update `hosts/nixos-ci/secrets.yaml` with `sops edit`.
3. Re-apply: `nixos-rebuild switch --flake .#nixos-ci`.

## Apply changes

Remote:

```bash
nixos-rebuild switch --flake .#nixos-ci --target-host <user>@<ip> --elevate=sudo
```

Inside the container:

```bash
sudo nixos-rebuild switch --flake .#nixos-ci
```
