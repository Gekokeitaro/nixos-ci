# Decision Log

Architectural and design decisions for the nixos-ci project.
Agents must append new entries here and keep this file under 300 lines.

---

## 2026-05-26 — Initial GPU driver architecture

**Context**: LXC containers could not access the AMD 680M (gfx1035) iGPU.

**Decision**: Split GPU support into two layers:

- `common/config/default.nix` enables `hardware.graphics` (Mesa/libdrm base)
  for all hosts.
- `hosts/llamaswap-lxc/configuration.nix` conditionally loads Vulkan or ROCm
  runtime packages based on the `isLlamacppRocm` flag passed via `specialArgs`.

**Rationale**: The base host (`nixos-ci`) only compiles llama-cpp — Nix handles
build-time deps in its sandbox, so no system-level GPU drivers are needed there.
Runtime drivers are only required in the container that actually executes
`llama-server`.

---

## 2026-05-26 — amdvlk removed, RADV is default

**Context**: `amdvlk` was removed from nixpkgs. Build failed with
`'amdvlk' has been removed since it was deprecated by AMD`.

**Decision**: Use only `vulkan-loader` in `hardware.graphics.extraPackages` for
the Vulkan profile. RADV (the replacement) already ships with Mesa, which is
installed via `hardware.graphics.enable = true`.

---

## 2026-05-26 — Unprivileged LXC containers only

**Context**: Project targets Proxmox deployment.

**Decision**: All LXC containers are and will always be **unprivileged**.
No configuration should rely on privileged container features. GPU device
access must go through Proxmox's unprivileged passthrough
(`lxc.cgroup2.devices.allow`).

---

## 2026-05-26 — No Nix CLI on the dev host

**Context**: The development machine is not NixOS.

**Decision**: Agents must never run `nix`, `nix-build`, `nix-shell`,
`nixos-rebuild`, or any Nix CLI command on the dev host. Validation is done
by reading and reasoning about the Nix expressions, or by the user on the
actual NixOS LXC containers.

---

## 2026-05-26 — Package overrides via direct import, not overlays

**Context**: Custom packages (e.g., `llama-cpp`) need to be consumed by hosts.

**Decision**: Packages are imported directly with
`import ../../packages/<name> {inherit pkgs ...;}` from the host configuration.
They are **not** exposed as flake `packages` outputs or as nixpkgs overlays.
This keeps the flake surface minimal and the dependency chain explicit.

---

## 2026-05-26 — One model per .nix file

**Context**: llama-swap serves multiple LLM models with different configurations.

**Decision**: Each model is defined in its own `.nix` file under
`hosts/llamaswap-lxc/models/`, with signature `{llama-server}: { ... }`.
Models are composed via `lib.mkMerge`. This keeps model configs isolated,
easy to add/remove, and avoids monolithic configuration files.

---

## 2026-05-26 — Comment language is Spanish

**Context**: Project maintained by a Spanish-speaking developer.

**Decision**: All inline code comments are written in Spanish. Documentation
files (`AGENTS.md`, `DECISIONS.md`, `README.md`) are in English for broader
agent compatibility.

---

## 2026-05-26 — HSA_OVERRIDE_GFX_VERSION for gfx1035

**Context**: The AMD 680M uses the gfx1035 GPU architecture, which is not
officially listed in ROCm's supported hardware.

**Decision**: Set `HSA_OVERRIDE_GFX_VERSION = "10.3.0"` as an environment
variable in the ROCm profile to force compatibility. This may need updating
if ROCm adds official gfx1035 support in the future.

---

## 2026-05-26 — Mesa shader cache configuration for llama-swap

**Context**: Using Vulkan in unprivileged containers caused warnings from Mesa:
`Failed to create //.cache for shader cache (Read-only file system)---disabling.`
This happened because the systemd service for llama-swap runs as a system user
without a writeable home directory.

**Decision**: Set `MESA_SHADER_CACHE_DIR` and `XDG_CACHE_HOME` to `/var/cache/llama-swap`
in the `llama-swap` systemd service environment, and enable systemd's
`CacheDirectory = "llama-swap"` to dynamically create and manage the directory with
proper permissions.

---

## 2026-05-26 — Automated llama-cpp updates

**Context**: Upgrading llama.cpp required manually finding the latest GitHub release version and prefetching the SHA-256 hash using external commands, then manually editing `packages/llama-cpp/default.nix`.

**Decision**: Implement a declarative flake application (`apps.x86_64-linux.update-llama-cpp`). Following the "flakes aren't real" philosophy (keeping `flake.nix` thin and free of heavy logic), the shell script definition is located in a dedicated file `utils/update-llama-cpp.nix` and imported inside `flake.nix`. When run manually, it queries the GitHub API for the latest release, prefetches the new hash using `nix-prefetch-github`, and edits `default.nix` in place.

---

## 2026-05-30 — lockup_timeout over nodes_per_submit for DeviceLost

**Context**: Attempting to fix the `DeviceLost` error on the AMD iGPU by lowering `nodes_per_submit` to `1` in `llama-cpp` resulted in an unacceptable performance loss.

**Decision**: The `nodes_per_submit` patch in the `llama-cpp` package is retained strictly for performance fine-tuning, as it is not a viable fix for stability in this case. The viable solution to prevent `DeviceLost` crashes remains the host-level workaround of increasing `amdgpu.lockup_timeout`.

---

## 2026-07-26 — environment.systemPackages en lugar de users.users.\<name\>.packages

**Context**: El host `nixos-forgejo` usaba `users.users.nixos-forgejo.packages`, que no está soportado en NixOS (solo existe en home-manager).

**Decision**: Todos los paquetes del sistema (herramientas CLI, utilidades) se declaran en `environment.systemPackages`. La opción `users.users.<name>.packages` queda reservada exclusivamente para configuraciones home-manager, nunca en módulos NixOS puros.

---

## 2026-07-26 — Fix de /sbin/init para que nixos-rebuild switch persista entre reboots

**Context**: En imágenes LXC construidas con `nixos-rebuild build-image`, `/sbin/init` es un fichero estático copiado del store original (permisos `-r-xr-xr-x`, timestamp epoch 1970). Proxmox lo ejecuta directamente en cada arranque, ignorando el perfil actualizado por `nixos-rebuild switch`. Resultado: cualquier cambio aplicado dentro del LXC desaparecía tras un reinicio.

**Decision**: Añadir `system.activationScripts.updateSbinInit` en `common/config/default.nix`. Este script se ejecuta en cada `nixos-rebuild switch` y reemplaza el fichero estático con un symlink a `/nix/var/nix/profiles/system/init`. Así, cada boot usa la generación correcta del perfil activo.

**Rationale**: La alternativa (reconstruir y redesplegar la imagen completa tras cada cambio) es costosa y rompe el flujo de desarrollo habitual. El activation script es mínimo, idempotente y aplica a todos los hosts vía `common/`.
