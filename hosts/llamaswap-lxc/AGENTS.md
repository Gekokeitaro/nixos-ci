# AGENTS.md — llamaswap-lxc

Context guide for LLM agents working on the `llamaswap-lxc` host.

## Purpose

Serves local LLM models via llama-swap + llama-cpp with GPU acceleration.
Single `configuration.nix` is parameterized by `specialArgs` to produce two
flake outputs: `nixos-llamaswap-vulkan` and `nixos-llamaswap-rocm`.

## Services & ports

| Service | Port | Notes |
|---|---|---|
| llama-swap | 8080 | OpenAI-compatible API, `listenAddress = 0.0.0.0` |

## Dependencies

- GPU on the Proxmox host, passed through via `/dev/dri` (see Constraints).
- GGUF models mounted at `/models/` (outside Nix, on Proxmox host).
- `packages/llama-cpp` — parameterized override; version/hash are `let`
  variables at the top of `packages/llama-cpp/default.nix`.
- `utils/update-llama-cpp.nix` — script exposed as `nix run .#update-llama-cpp`;
  queries GitHub for latest llama.cpp release and updates
  `packages/llama-cpp/default.nix` in place.

## Secrets

No sops-nix configuration. GPU/cache paths are not secret.

## Special config

- `specialArgs`: `isLlamacppRocm` (bool) and `hostName` are passed from
  `flake.nix`; default `isLlamacppRocm ? false`.
- `llamaCpp = import ./packages/llama-cpp {inherit pkgs isLlamacppRocm;}`.
- `llama-server-delayed`: wrapper script adds `sleep 2` before exec to avoid
  DeviceLost errors on model swap (GPU needs time to clear state).
- `lib.mkMerge` composes model definitions from `./models/` (one file per model).
- Vulkan profile: `AMD_VULKAN_ICD=RADV`, `vulkan-loader`, `hardware.graphics.extraPackages`.
- ROCm profile: `rocmPackages.clr{,.icd}`, `HSA_OVERRIDE_GFX_VERSION=10.3.0`.
- Both: `GGML_VK_MAX_NODES_PER_SUBMIT=1`, `GGML_CUDA_ENABLE_UNIFIED_MEMORY=1`.
- `MESA_SHADER_CACHE_DIR` / `XDG_CACHE_HOME` → `/var/cache/llama-swap` for the
  llama-swap systemd service.
- User `nixos-llamaswap-vulkan` or `nixos-llamaswap-rocm` (per `hostName`)
  with `extraGroups = ["wheel" "render" "video"]`.

## Constraints

- Unprivileged LXC: GPU access requires Proxmox passthrough
  (`lxc.cgroup2.devices.allow: c 226:* rwm` + `/dev/dri` bind mount).
- Fixed GPU target: `gfx1035` (AMD 680M). Change `gpuArch` in
  `packages/llama-cpp/default.nix` for a different GPU.
- On slow iGPUs, `lockup_timeout` may need raising on the Proxmox host
  (see README). Outside Nix scope.
- `hostName` specialArg is mandatory — the module has no default.

## Modification guide

### Adding a model

1. Create `hosts/llamaswap-lxc/models/<model-name>.nix` with signature
   `{llama-server}: { "model-name" = { … }; }`.
2. Import it in `configuration.nix` inside the `lib.mkMerge` of
   `services.llama-swap.settings.models`, passing
   `{llama-server = llama-server-delayed;}`.
3. Update `matrix.vars` and `matrix.evict_costs` if the model participates
   in inference sets.

### Updating llama-cpp

```bash
nix run .#update-llama-cpp
```

This script queries the GitHub API for the latest llama.cpp release, prefetches
the new hash, and updates `packages/llama-cpp/default.nix` in place. Manual
alternative: `nix-prefetch-github ggml-org llama.cpp --rev "$LATEST"` and edit
the `llamacppVersion` / `llamacppHash` `let` variables.