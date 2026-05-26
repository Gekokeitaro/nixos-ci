# CLAUDE.md

Context guide and best practices for LLM agents working on this repository.

## Project description

Declarative NixOS configurations repository aimed at building **LXC images**
ready to deploy on Proxmox. It includes:

- A base host (`nixos-lxc`) as a generic template.
- A specialized host (`llamaswap-lxc`) integrating `llama-swap` + `llama-cpp`
  to serve LLM models via an OpenAI-compatible API.
- Shared Neovim configuration (nvf) included in all images.

## Repository structure

```
.
├── flake.nix                  # Entry point. Defines nixosConfigurations.
├── flake.lock
├── common/
│   ├── default.nix            # Aggregates config/ and modules/ via imports.
│   ├── config/
│   │   └── default.nix        # LXC base: boot.isContainer, graphics, openssh, sudo…
│   └── modules/
│       ├── default.nix        # Aggregates modules (currently only nvf).
│       └── nvf/
│           ├── default.nix    # Full Neovim (nvf) configuration.
│           └── keymaps.nix    # Extracted keymaps (currently not imported).
├── hosts/
│   ├── nixos-lxc/
│   │   ├── configuration.nix  # Basic template host.
│   │   └── README.md
│   └── llamaswap-lxc/
│       ├── configuration.nix  # Host with llama-swap + llama-cpp.
│       ├── README.md
│       └── models/            # LLM model definitions (one .nix file each).
│           ├── qwen3-embedding-0.6B_Q8_0.nix
│           ├── gemma-4-E4B-it-UD-Q4_K_XL.nix
│           └── bge-reranker-v2-m3-q8_0.nix
└── packages/
    └── llama-cpp/
        └── default.nix        # Parameterized llama-cpp override (Vulkan/ROCm).
```

## Nix conventions

### General style

- **Formatter**: Nix code uses `alejandra` formatting (no trailing commas, no
  unnecessary `with`, aligned attributes).
- **Comment language**: Spanish. Inline comments are written in Spanish.
- **`let … in`**: prefer `let` at the beginning of the module to define local
  variables before the main attrset.
- **`lib`**: obtained from `pkgs.lib` in files that receive `pkgs` as an
  argument (not as a NixOS module input).

### Module pattern

- `common/default.nix` **aggregates** subdirectories with
  `imports = [./config ./modules];`.
- Each subdirectory exposes a `default.nix` as its entry point.
- Modules in `common/` apply to **all** hosts.

### Hosts

- Each host lives in `hosts/<name>/configuration.nix`.
- All hosts import `../../common` as their base.
- Host-specific parameters are passed via `specialArgs` in `flake.nix`
  (e.g., `isLlamacppRocm`).
- `?` is used for default values in module arguments
  (`isLlamacppRocm ? false`).

### Packages (overrides)

- Custom packages live in `packages/<name>/default.nix`.
- They are consumed with `import ../../packages/<name> {inherit pkgs ...;}`
  from the host, **not** as an overlay or as flake `packages`.
- For heavy overrides, use the pattern
  `(pkgs.package.override { … }).overrideAttrs (oldAttrs: { … })`.
- Versions and hashes are defined as `let` variables at the top of the file.

### LLM models (llama-swap)

- Each model is defined in an independent `.nix` file inside
  `hosts/llamaswap-lxc/models/`.
- File signature: `{llama-server}: { "model-name" = { … }; }`.
- They are composed with `lib.mkMerge` in the host's `configuration.nix`.
- The path to the `llama-server` binary is interpolated with `${llama-server}`.
- GGUF files are assumed to be mounted at `/models/`.

## Rules for modifications

### Adding a new host

1. Create `hosts/<name>/configuration.nix`.
2. Import `../../common` in the `imports`.
3. Define user, SSH keys, packages, and `system.stateVersion`.
4. Add the corresponding `nixosConfiguration` in `flake.nix`.
5. Create `hosts/<name>/README.md` with build instructions.

### Adding a new LLM model

1. Create `hosts/llamaswap-lxc/models/<model-name>.nix` following the
   `{llama-server}: { … }` signature.
2. Import the file in `hosts/llamaswap-lxc/configuration.nix` inside the
   `lib.mkMerge` of `services.llama-swap.settings.models`.
3. Update `matrix.vars` and `matrix.evict_costs` if the model participates
   in inference sets.

### Adding a new shared module

1. Create `common/modules/<name>/default.nix`.
2. Add `./name` to the `imports` array in `common/modules/default.nix`.

### Updating llama-cpp

1. Edit `packages/llama-cpp/default.nix`:
   - Change `llamacppVersion` to the new build number.
   - Update `llamacppHash` (see instructions in
     `hosts/llamaswap-lxc/README.md` for obtaining the hash with
     `nix-prefetch-github`).

## Build and deployment

```bash
# Build LXC image (base host)
nixos-rebuild build-image --image-variant lxc --flake .#nixos-ci

# Build LXC image (llamaswap with Vulkan)
nixos-rebuild build-image --image-variant lxc --flake .#nixos-llamaswap-vulkan

# Build LXC image (llamaswap with ROCm)
nixos-rebuild build-image --image-variant lxc --flake .#nixos-llamaswap-rocm
```

The result is a **symlink** (`result`) pointing to the `.tar.gz` in the Nix
store. This tarball is imported directly into Proxmox as an LXC template.

## Things to keep in mind

- **All LXC containers are unprivileged.** Never assume root-level access to
  host devices or privileged cgroup operations. Proxmox must explicitly grant
  device access (e.g., `/dev/dri`) via the LXC config file.
- **`boot.isContainer = true`**: all hosts are LXC containers, not VMs.
  Do not include bootloader or hardware configuration.
- **`systemd.suppressedSystemUnits`**: unnecessary units in containers are
  suppressed (`dev-mqueue.mount`, `sys-kernel-debug.mount`,
  `sys-fs-fuse-connections.mount`).
- **Hardened SSH**: password auth and kbd-interactive are disabled. Public
  keys only.
- **`nixpkgs` follows `nixos-unstable`**: dependencies use the unstable
  channel.
- **`nvf.inputs.nixpkgs.follows`**: nvf shares the same nixpkgs as the flake
  to avoid duplication.
- **Configuration files do not travel to the image**: after creating the
  container, you must re-clone or recreate the configuration inside it.
- **Fixed GPU target**: the llama-cpp override targets `gfx1035` (AMD 680M).
  Change `gpuArch` if using a different GPU.

### GPU driver architecture

GPU support is split into two layers:

| Layer | Location | What it provides |
|---|---|---|
| Base graphics stack | `common/config/default.nix` | `hardware.graphics.enable = true` (Mesa, libdrm) |
| Profile-specific runtime | `hosts/llamaswap-lxc/configuration.nix` | Vulkan: `vulkan-loader`, `amdvlk`, `AMD_VULKAN_ICD=RADV` |
| | | ROCm: `rocmPackages.clr{,.icd}`, `HSA_OVERRIDE_GFX_VERSION=10.3.0` |
| Build-time dependencies | `packages/llama-cpp/default.nix` | Handled automatically by `.override { vulkanSupport/rocmSupport }` |
| Proxmox host (outside Nix) | `/etc/pve/lxc/<id>.conf` | `lxc.cgroup2.devices.allow: c 226:* rwm` + `/dev/dri` bind mount |

## Critical rules

- **NEVER run `nix`, `nix-build`, `nix-shell`, `nixos-rebuild`, or any Nix
  CLI command.** The development host is **not** NixOS. These commands are
  unavailable and will fail. Code changes should be validated by reading and
  reasoning about the Nix expressions only.
- **All containers are unprivileged.** Never add configuration that requires
  privileged LXC features. GPU and device access must go through Proxmox's
  unprivileged device passthrough (`lxc.cgroup2.devices.allow`).
