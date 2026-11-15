# AGENTS.md — llamaswap-lxc

Context guide for LLM agents working on the `llamaswap-lxc` host.

## Purpose

Serves local LLM models via llama-swap + llama-cpp with GPU acceleration.
Single `configuration.nix` is parameterized by `specialArgs` to produce two
flake outputs: `nixos-llamaswap-vulkan` and `nixos-llamaswap-rocm`.

## Services & ports

| Service | Port | Notes |
|---|---|---|
| llama-swap | 8080 | OpenAI-compatible API, `listenAddress = 0.0.0.0`; ROCm host address in [INFRA.md](../../INFRA.md) |

## Deployment

- `nixos-llamaswap-rocm` is deployed automatically from `main` by the Forgejo
  workflow on `nixos-ci`. Pushing to `main` runs `nixos-rebuild switch`.
- The `llamaswap-rocm` branch runs `nixos-rebuild test`: it activates the
  configuration in the running system without making it the boot default, so a
  reboot reverts it.
- `nixos-llamaswap-vulkan` is applied manually.

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
- A model id is unique across `models/`: a duplicate aborts evaluation.
- A model file opens with `{llama-server, modelLib}:`; `llama-server` is the
  delayed wrapper and `modelLib` the fragment library, imported once in
  `models/default.nix`. The shape:
  [`skills/model-files/references/module-shape.md`](../../skills/model-files/references/module-shape.md).
- A speculative preset is a second attribute in the same file (`"… MTP"`),
  sharing the base `cmd` and `filters` through a `let`, not by repeating them.
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
- Fixed GPU target: `gfx1035` (AMD 680M). Change `targetGPU` in
  `packages/llama-cpp/default.nix` for a different GPU.
- On slow iGPUs, `lockup_timeout` may need raising on the Proxmox host
  (see README). Outside Nix scope.
- `hostName` specialArg is mandatory — the module has no default.

## Modification guide

Adding or archiving a model has prerequisites and gotchas: see
[`skills/model-files/SKILL.md`](../../skills/model-files/SKILL.md).

### Updating llama-cpp

```bash
nix run .#update-llama-cpp
```

This script queries the GitHub API for the latest llama.cpp release, prefetches
the source hash, forces the npm-deps hash mismatch to discover the new value,
and updates `llamacppVersion`, `llamacppHash` and `llamacppNpmHash` in place.
It requires a Nix host because it evaluates `pkg.npmDeps`.

### Updating the benchmark scripts

```bash
nix run .#update-llama-bench-runner
```

It reads `refs/heads/main` of `llama-bench-runner`, prefetches the hash and
rewrites `llamaBenchRunner`'s `rev` and `hash` in `configuration.nix`. The deploy
workflow runs it on every push, so a manual bump is only needed when working
outside CI. It is idempotent: when the pin already matches the remote it exits
without prefetching, and a network failure leaves the committed pin in place.

## Sampling and filters

Sampling is set in two places, and they are not interchangeable:

- **`cmd` in the model file** — server flags (`--temp`, `--top-k`,
  `--samplers`…): the default for every request that model serves. The parts two
  models share come from `models/lib/default.nix` (`deviceArgs`, `memDefault`,
  `dryArgs`), never from a copy in each file.
- **`filters.setParamsByID`** — request parameters for one variant
  (`dry_multiplier`, `reasoning_budget`…), applied when the client id carries the
  suffix.

Nothing here can tune sampling by measuring speed: `llama-bench` has no sampler
flags, so a battery sees t/s and VRAM only. Whether a sampling change is good is
a question about output quality, judged outside this host.

The chain (its default and override order), what each sampler does, the
penalties, DRY, the reasoning budget and the speculative flags:
[`skills/sampling/SKILL.md`](../../skills/sampling/SKILL.md). What is still open
on this host is in `MEMORY.md`.

## Skills

Owned by this repository, in `skills/<id>/SKILL.md` with the long detail in
`references/` beside it. The workspace root lists `nixos-ci/skills` in
`opencode.json`, so OpenCode discovers them.

| Skill | Use when | Owns |
|---|---|---|
| `model-files` | adding, renaming or archiving a model under `models/` | the file signature, the `git add` flakes require, `/models/`, the speculative preset attribute, archiving, the add-model checklist |
| `sampling` | changing the sampler chain or the filters of a model | the two places, the chain order and defaults, each sampler, the penalties, DRY, the reasoning budget, the `--spec-*` flags |

Load the `caveman` skill at the start of every session (`skill` tool, id `caveman`).
