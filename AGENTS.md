# AGENTS.md

Context guide and best practices for LLM agents working on this repository.

## Decision log

All architectural and design decisions are recorded in
[DECISIONS.md](./DECISIONS.md). **Agents must**:

1. **Read** `DECISIONS.md` before making changes to understand prior context.
2. **Append** a new entry whenever a decision is made (new pattern, dependency
   change, architectural choice, deprecation, etc.): date, context, decision,
   rationale.
3. **Never consolidate or rewrite an accepted entry.** At 300 lines the log is
   frozen where it stands and new decisions become ADRs under `docs/adr/`; a
   later ADR supersedes an earlier one instead of editing it.

What is deployed on each host right now lives in [MEMORY.md](./MEMORY.md), not
here: this file explains how the repo works, that one records state. Addresses,
ports, and service dependencies live in [INFRA.md](./INFRA.md).

## Documentation map

| Question | Document |
|---|---|
| How does the repo work? What are the rules? | `AGENTS.md` (this file) |
| What is deployed, on which branch, and what is pending? | `MEMORY.md` |
| Which host is at which address, with which ports and dependencies? | `INFRA.md` |
| Why was a decision made? | `DECISIONS.md` |
| How do I build, boot, or apply this host? | `hosts/<name>/README.md` |
| What must an agent know before touching this host? | `hosts/<name>/AGENTS.md` |

Volatile facts (addresses, ports, versions, model ids, deployed status) have a
single owner: `INFRA.md`, `MEMORY.md`, or the configuration file itself. Host
documentation links to the owner instead of copying the value.

## Project overview

Declarative NixOS configurations for building **LXC images** on Proxmox.
Includes a base host template and specialized hosts (e.g., llama-swap for
local LLM inference). All hosts share a common base with NVF (Neovim).

## Repository structure

```
.
├── flake.nix                  # Entry point. Defines nixosConfigurations.
├── flake.lock
├── AGENTS.md                  # This file. Agent context and best practices.
├── DECISIONS.md               # Decision log (see above).
├── INFRA.md                   # Network and service inventory (addresses, ports).
├── MEMORY.md                  # Deployed state per host (see above).
├── .forgejo/
│   └── workflows/
│       └── deploy-llamaswap-rocm.yml  # CI: deploy/test llamaswap-rocm.
├── common/
│   ├── default.nix            # Aggregates config/ and modules/ via imports.
│   ├── config/
│   │   └── default.nix        # LXC base: boot.isContainer, graphics, openssh, sudo…
│   ├── modules/
│   │   ├── default.nix        # Aggregates modules: nvf + sops-nix.
│   │   ├── nvf/
│   │   └── sops-nix/
│   ├── secrets/
│   │   └── postgresql-shared.yaml  # Shared DB passwords (n8n, hindsight).
│   └── secrets.yaml
├── hosts/
│   ├── llamaswap-lxc/         # llama-swap + llama-cpp (GPU)
│   │   ├── models/            # One .nix file per model; archived/ keeps dead ones.
│   │   └── packages/
│   │       └── llama-cpp/
│   │           └── default.nix  # Parameterized llama-cpp override (Vulkan/ROCm).
│   ├── nixos-pi-agent/        # pi-coding-agent sessions; inference via OmniRoute
│   │   ├── config/            # models.json, settings.json
│   │   ├── modules/
│   │   │   └── pi-coding-agent/
│   │   │       └── default.nix  # piCodingAgent module
│   │   ├── AGENTS.md
│   │   └── README.md
│   ├── nixos-ci/              # Dev machine + two Forgejo runners
│   │   └── modules/
│   │       └── forgejo-runner.nix  # Runner `ci`: host label + deploy key.
│   ├── nixos-forgejo/         # Self-hosted Git forge (Forgejo, SQLite)
│   ├── nixos-calibre-wa/      # Calibre-Web-Automated + rclone pCloud
│   ├── nixos-n8n/             # n8n workflow automation (OCI + PostgreSQL)
│   ├── nixos-n8n-runner/      # n8n task runners (OCI)
│   ├── nixos-omniroute/       # OmniRoute AI gateway (OCI)
│   ├── nixos-postgresql/      # Central PostgreSQL + pgvector
│   ├── nixos-hindsight/       # Hindsight data platform (OCI + LLM)
│   └── pihole-lxc/            # Legacy Pi-hole config; not wired into flake.nix.
└── utils/
    └── update-llama-cpp.nix   # Script to update llama-cpp version/hash.
```

## CI/CD and deployment

- Forgejo Actions runs on the `nixos-ci` host. There are two runner instances:
  `ci` (label `host:host`, used for deployment) and `nixos-runner` (label
  `docker`, used for containerized jobs).
- `.forgejo/workflows/deploy-llamaswap-rocm.yml` deploys the ROCm host:
  - push to `main` → `nixos-rebuild switch` against `nixos-llamaswap-rocm`;
  - push to `llamaswap-rocm` → `nixos-rebuild test` (build without activating).
- The deploy key is the sops secret `deploy-key`; systemd exposes it to
  `forgejo-runner-ci` as a credential.
- Only `nixos-llamaswap-rocm` is automated. The rest of the hosts are applied
  manually. A push to `main` is therefore a production action: do not push
  configuration that is not ready to deploy.

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
  (e.g., `isLlamacppRocm`, `hostName`).
- `?` is used for default values in module arguments
  (`isLlamacppRocm ? false`).
- `nixos-llamaswap-vulkan` and `nixos-llamaswap-rocm` share
  `hosts/llamaswap-lxc/configuration.nix`; only `specialArgs` differ.
  `hostName` has no default there and is mandatory.

### Packages (overrides)

- Host-specific packages live in `hosts/<name>/packages/<name>/default.nix`.
- They are consumed with `import ./packages/<name> {inherit pkgs ...;}`
  from the host, **not** as an overlay or as flake `packages`.
- For heavy overrides, use the pattern
  `(pkgs.package.override { … }).overrideAttrs (oldAttrs: { … })`.
- Versions and hashes are defined as `let` variables at the top of the file.

### "Flakes aren't real" philosophy

- **Thin Wrapper**: `flake.nix` must remain a very thin wrapper containing only inputs declarations and top-level schema mapping outputs.
- **No Inline Logic**: Any package definition, complex NixOS module, custom helper, development script, or shell declaration must NOT live inside `flake.nix`.
- **Modularity**: Move all logic to dedicated Nix files (e.g., under `packages/` or `utils/`) and import them into `flake.nix`. This preserves cross-compilation compatibility, clean parameterization, and makes evaluation logic testable outside of flakes.

## Rules for modifications

### Adding a new host

1. Create `hosts/<name>/configuration.nix`.
2. Import `../../common` in the `imports`.
3. Define user, SSH keys, packages, and `system.stateVersion`.
4. Add the corresponding `nixosConfiguration` in `flake.nix`.
5. Add the host to `INFRA.md` (role, address, ports, dependencies).
6. Create `hosts/<name>/README.md` with build instructions and
   `hosts/<name>/AGENTS.md` with the agent-facing invariants (purpose,
   interfaces, secrets, constraints, modification guide).
7. For host-specific modules, create `hosts/<name>/modules/<name>/default.nix` and import it from `configuration.nix`.

### Adding a new shared module

1. Create `common/modules/<name>/default.nix`.
2. Add `./name` to the `imports` array in `common/modules/default.nix`.

## Constraints

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
  Immediately after starting the container for the first time, run `nix-channel --update`.

## Critical rules

- **NEVER run `nix`, `nix-build`, `nix-shell`, `nixos-rebuild`, or any Nix
  CLI command.** The development host is **not** NixOS. These commands are
  unavailable and will fail. Code changes should be validated by reading and
  reasoning about the Nix expressions only.
- **All containers are unprivileged.** Never add configuration that requires
  privileged LXC features. GPU and device access must go through Proxmox's
  unprivileged device passthrough (`lxc.cgroup2.devices.allow`).
