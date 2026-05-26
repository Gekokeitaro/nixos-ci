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
