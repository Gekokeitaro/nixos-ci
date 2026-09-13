# NixOS LXC

> Repository for building, deploying, and updating NixOS LXC images for my homelab on Proxmox.

## Hosts

| Host | Description |
| --- | --- |
| [nixos-ci](hosts/nixos-ci/) | Dev machine + Forgejo CI/CD runner |
| [nixos-forgejo](hosts/nixos-forgejo/) | Self-hosted Git forge (Forgejo) |
| [llamaswap-lxc](hosts/llamaswap-lxc/) | Local LLM inference via llama-swap + llama-cpp (Vulkan/ROCm) |
| [nixos-calibre-wa](hosts/nixos-calibre-wa/) | Calibre-Web-Automated + pCloud library |
| [nixos-n8n](hosts/nixos-n8n/) | n8n workflow automation (OCI + PostgreSQL) |
| [nixos-n8n-runner](hosts/nixos-n8n-runner/) | n8n external task runners (OCI) |
| [nixos-omniroute](hosts/nixos-omniroute/) | OmniRoute AI gateway (OCI) |
| [nixos-postgresql](hosts/nixos-postgresql/) | Central PostgreSQL + pgvector |
| [nixos-hindsight](hosts/nixos-hindsight/) | Hindsight data platform (OCI + LLM) |

> [!NOTE]
> All LXC images include NVF (Neovim) as the text editor.

## Deployment workflow

### 1. SSH keys (mandatory)

SSH public keys **must** be defined in the host's `configuration.nix` before
generating the image. Without them, remote deployment will fail.

### 2. Generate the LXC image

```bash
nixos-rebuild build-image --image-variant lxc --flake .#<host>
```

This creates a `result` symlink pointing to a `.tar.gz` in the Nix store.
Import that tarball into Proxmox as an LXC template, then create and start
the container.

### 3. Apply configuration remotely

Once the container is running and reachable via SSH:

```bash
nixos-rebuild switch --flake .#<host> --target-host <user>@<ip> --elevate=sudo
```

> [!CAUTION]
> Applying the config of the wrong host can brick the container. `nixos-rebuild`
> recompiles the entire system based on the selected `configuration.nix`. If the
> target system differs (wrong hostname, missing hardware, different packages),
> you may lose SSH access with no way to recover except rebuilding.

### Other commands

| Command | Description |
| --- | --- |
| `nix flake show .` | List all available flake outputs |
| `nixos-rebuild switch --flake .#<host>` | Apply config to the local machine |

> [!NOTE]
> `build-image` produces a tarball that includes the applied configuration but
> **not** the NixOS config files themselves. Any future `nixos-rebuild switch`
> inside the container will use whatever configuration was baked into the image
> until you re-clone or recreate the config files.
