# nixos-omniroute

LXC running [OmniRoute](https://github.com/diegosouzapw/omniroute) — an AI
gateway providing a unified OpenAI-compatible endpoint across multiple LLM
providers. Used by `nixos-hindsight` as its LLM backend.

## Build

```bash
nixos-rebuild build-image --image-variant lxc --flake .#nixos-omniroute
```

## Exposed ports

| Service | Port |
|---|---|
| OmniRoute (AI gateway) | 20128 |

## First boot

1. Import the tarball as template in Proxmox, create and start the LXC
   (1–2 CPU, 1–2 GB RAM, 5 GB disk).
2. Data persists at `/var/lib/omniroute` (bind mount to host, created by
   `tmpfiles`).
3. `OMNIROUTE_BOOTSTRAPPED = "true"` skips the first-run wizard. Remove
   this line if you want to re-run the wizard from scratch.
4. Open `http://<IP>:20128` in a browser to access the OmniRoute UI.

## SSH

```bash
ssh nixos-omniroute@<IP>
```

## Apply changes

Remote:

```bash
nixos-rebuild switch --flake .#nixos-omniroute --target-host <user>@<ip> --elevate=sudo
```

Inside the container:

```bash
sudo nixos-rebuild switch --flake .#nixos-omniroute
```
