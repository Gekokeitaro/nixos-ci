# llamaswap-lxc

LXC for serving local LLMs via llama-swap + llama-cpp. Two GPU backends share
the same `configuration.nix` and diverge only through `specialArgs` in
`flake.nix`.

| Flake target | Backend | Flake `specialArgs` |
|---|---|---|
| `nixos-llamaswap-vulkan` | Vulkan (RADV) | `isLlamacppRocm = false` |
| `nixos-llamaswap-rocm` | ROCm | `isLlamacppRocm = true` |

The llama-cpp package is the upstream Nix one tuned for the latest version
with either backend. See `packages/llama-cpp/default.nix`. Updates via
`nix run .#update-llama-cpp`.

## Build

```bash
# Vulkan
nixos-rebuild build-image --image-variant lxc --flake .#nixos-llamaswap-vulkan

# ROCm
nixos-rebuild build-image --image-variant lxc --flake .#nixos-llamaswap-rocm
```

## Proxmox configuration

### GPU passthrough

To expose the AMD iGPU to the unprivileged LXC:

1. Create the container; start it once; inside the LXC run:

   ```bash
   getent group render | cut -d: -f3
   getent group video | cut -d: -f3
   # → Ex: 303, 26
   ```

2. In Proxmox: **Resources** → **Add** → **Device Passthrough**
   - Device `/dev/dri/renderD128`, mode `0666`, UID `0`, GID from step 1.
   - Repeat for `/dev/dri/card0` and `/dev/kfd` (ROCm).
3. Restart the LXC.

4. Verify from inside:

   ```bash
   ls -l /dev/dri
   # Vulkan
   nix shell nixpkgs#vulkan-tools -c vulkaninfo --summary
   # ROCm
   nix shell nixpkgs#rocmPackages.rocminfo -c rocminfo
   ```

### GPU job timeout workaround

On slow iGPUs/APUs, a batched inference submission can exceed the kernel
`lockup_timeout` (2000ms), causing the GPU compute ring to reset.
See [ggml-org/llama.cpp#21724](https://github.com/ggml-org/llama.cpp/issues/21724).

On the **Proxmox host**:

```bash
echo "options amdgpu lockup_timeout=30000" > /etc/modprobe.d/amdgpu.conf
update-initramfs -u -k all && reboot
```

## Exposed ports

| Service | Port |
|---|---|
| llama-swap (OpenAI-compatible API) | 8080 |

## Models

GGUFs are expected at `/models/` (mounted from the Proxmox host).
Each model is a single Nix file in `models/` with signature
`{llama-server}: { "model-name" = { … }; }`, composed with `lib.mkMerge`
in `configuration.nix`. The binary path is interpolated as `${llama-server}`
(aliased to a delayed wrapper with `sleep 2` to avoid DeviceLost on swap).

To add a model: create `models/<name>.nix`, import it in the `lib.mkMerge`
of `services.llama-swap.settings.models`, update `matrix.vars` and
`matrix.evict_costs` if it participates in inference sets.

## First boot

1. Import the generated tarball as template in Proxmox and create the LXC.
2. Configure GPU passthrough as above.
3. Mount `/models/` with GGUF files onto the LXC (bind mount in Proxmox).
4. Start the container; confirm `llama-swap` is listening on `:8080`.

## SSH

```bash
ssh nixos-llamaswap-vulkan@<IP>  # or nixos-llamaswap-rocm@<IP>
```

## Apply changes

Remote:

```bash
nixos-rebuild switch --flake .#nixos-llamaswap-vulkan --target-host <user>@<ip> --elevate=sudo
```

Inside the container (after `nix-channel --update`):

```bash
sudo nixos-rebuild switch --flake .#nixos-llamaswap-vulkan
```
