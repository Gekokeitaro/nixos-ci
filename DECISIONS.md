# Decision Log

Architectural and design decisions for the nixos-ci project. Agents must append
new entries here and never rewrite an accepted one. At 300 lines this log is
frozen where it stands and new decisions become ADRs under `docs/adr/`.

---

## 2026-05-26 — Initial GPU driver architecture

**Context**: LXC containers could not access the AMD 680M (gfx1035) iGPU.

**Decision**: Split GPU support into two layers:

- `common/config/default.nix` enables `hardware.graphics` (Mesa/libdrm base) for
  all hosts.
- `hosts/llamaswap-lxc/configuration.nix` conditionally loads Vulkan or ROCm
  runtime packages based on the `isLlamacppRocm` flag passed via `specialArgs`.

**Rationale**: The base host (`nixos-ci`) only compiles llama-cpp — Nix handles
build-time deps in its sandbox, so no system-level GPU drivers are needed there.
Runtime drivers are only required in the container that actually executes
`llama-server`.

---

## 2026-05-26 — RADV as the only Vulkan driver

**Decision**: Use `vulkan-loader` (RADV) as the only Vulkan driver.
`amdvlk` was removed from nixpkgs and must not be used.

---

## 2026-05-26 — Unprivileged LXC containers only

**Context**: Project targets Proxmox deployment.

**Decision**: All LXC containers are and will always be **unprivileged**. No
configuration should rely on privileged container features. GPU device access
must go through Proxmox's unprivileged passthrough
(`lxc.cgroup2.devices.allow`).

---

## 2026-05-26 — No Nix CLI on the dev host

**Context**: The development machine is not NixOS.

**Decision**: Agents must never run `nix`, `nix-build`, `nix-shell`,
`nixos-rebuild`, or any Nix CLI command on the dev host. Validation is done by
reading and reasoning about the Nix expressions, or by the user on the actual
NixOS LXC containers.

---

## 2026-05-26 — Package overrides via direct import, not overlays

**Context**: Custom packages (e.g., `llama-cpp`) need to be consumed by hosts.

**Decision**: Packages are imported directly with
`import ./packages/<name> {inherit pkgs ...;}` from the host configuration.
They are **not** exposed as flake `packages` outputs or as nixpkgs overlays.
This keeps the flake surface minimal and the dependency chain explicit.

---

## 2026-05-26 — One model per .nix file

**Context**: llama-swap serves multiple LLM models with different
configurations.

**Decision**: Each model is defined in its own `.nix` file under
`hosts/llamaswap-lxc/models/`, with signature `{llama-server}: { ... }`. Models
are composed via `lib.mkMerge`. This keeps model configs isolated, easy to
add/remove, and avoids monolithic configuration files.

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
variable in the ROCm profile to force compatibility. This may need updating if
ROCm adds official gfx1035 support in the future.

---

## 2026-05-26 — Mesa shader cache configuration for llama-swap

**Context**: Using Vulkan in unprivileged containers caused warnings from Mesa:
`Failed to create //.cache for shader cache (Read-only file system)---disabling.`
This happened because the systemd service for llama-swap runs as a system user
without a writeable home directory.

**Decision**: Set `MESA_SHADER_CACHE_DIR` and `XDG_CACHE_HOME` to
`/var/cache/llama-swap` in the `llama-swap` systemd service environment, and
enable systemd's `CacheDirectory = "llama-swap"` to dynamically create and
manage the directory with proper permissions.

---

## 2026-05-26 — Automated llama-cpp updates

**Context**: Upgrading llama.cpp required manually finding the latest GitHub
release version and prefetching the SHA-256 hash using external commands, then
manually editing `hosts/llamaswap-lxc/packages/llama-cpp/default.nix`.

**Decision**: Implement a declarative flake application
(`apps.x86_64-linux.update-llama-cpp`). Following the "flakes aren't real"
philosophy (keeping `flake.nix` thin and free of heavy logic), the shell script
definition is located in a dedicated file `utils/update-llama-cpp.nix` and
imported inside `flake.nix`. When run manually, it queries the GitHub API for
the latest release, prefetches the new hash using `nix-prefetch-github`, and
edits `default.nix` in place.

---

## 2026-05-30 — GPU stability via lockup_timeout, not code patches

**Decision**: GPU stability is solved with `amdgpu.lockup_timeout` at the host
level. The `nodes_per_submit` patch in llama-cpp is only for performance
fine-tuning, not a stability fix.

---

## 2026-07-26 — environment.systemPackages for system packages

**Decision**: System packages are declared in `environment.systemPackages`.
`users.users.<name>.packages` is exclusive to home-manager, not pure NixOS
modules.

---

## 2026-07-26 — /sbin/init sync via activationScript

**Decision**: The `system.activationScripts.updateSbinInit` activation script in
`common/config/default.nix` replaces the static `/sbin/init` from the store with
a symlink to `/nix/var/nix/profiles/system/init` on every `nixos-rebuild switch`.
Without it, changes do not persist across LXC reboots.

---

## 2026-11-10 — One document per scope, memory split by repo

**Context**: Workspace documentation had grown by accretion: the root `AGENTS.md`
and `MEMORY.md` described both repos, `nixos-ci/AGENTS.md` mixed explanation with
deployed state, and this log was allowed to consolidate old entries into summary
bullets — which is exactly where the rationale of a decision gets lost.

**Decision**:

- Each scope owns its documents: root `AGENTS.md` (workspace, machines, rules),
  root `MEMORY.md` (current state), `GLOSSARY.md` (shared vocabulary),
  `nixos-ci/AGENTS.md` (how the hosts work) and this log (why).
- State lives in a `MEMORY.md` per repo. This repo's file records what is
  deployed on each host and what is pending; repo and branch state stay in the
  workspace root.
- This log no longer consolidates. Accepted entries are immutable: at 300 lines
  the log freezes and new decisions become ADRs under `docs/adr/`, superseding
  instead of editing.

**Rationale**: Every duplicate of a fact drifts, and a consolidated entry cannot
be audited. Splitting by owner means each file answers one question and can be
rewritten without touching the others.

---

## 2026-11-10 — Automatic deployment of llamaswap-rocm via Forgejo Actions

**Context**: Deploying the ROCm host required a manual `nixos-rebuild` after
every change. The Forgejo instance already had a runner on `nixos-ci`, but it
only exposed the `docker` label and was not wired to a deployment workflow.

**Decision**: Add a second runner instance, `ci`, with the label `host:host`,
and a Forgejo workflow at `.forgejo/workflows/deploy-llamaswap-rocm.yml`:

- pushes to `main` run `nixos-rebuild switch --flake .#nixos-llamaswap-rocm`;
- pushes to `llamaswap-rocm` run `nixos-rebuild test` (build without switching);
- the deploy key is the sops secret `deploy-key`, exposed to the runner service
  as a systemd credential.

Only `nixos-llamaswap-rocm` is automated. The remaining hosts stay manual.

**Rationale**: The ROCm host is the one that changes most often (llama.cpp
version, models, GPU parameters). Automating it removes a repeated manual step
while keeping the blast radius to a single host. A separate `host:host` runner
keeps privileged deployment jobs out of the containerized `docker` runner, and
the sops-backed credential avoids putting a private key in the repository or
the workflow file.
