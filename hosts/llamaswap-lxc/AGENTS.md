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
- The `llamaswap-rocm` branch only runs `nixos-rebuild test` (build, no switch).
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
- `models/default.nix` discovers every model file in `./models/` (one file per
  model); `archived/` is a directory and is ignored.
- Duplicate model ids make evaluation fail (`lib.unionOfDisjoint`), so two files
  cannot silently define the same model.
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

### Adding a model

1. Create `hosts/llamaswap-lxc/models/<model-name>.nix` with signature
   `{llama-server}: { "model-name" = { … }; }`.
2. `git add` the file: flakes only see files tracked by Git.
3. Ensure the GGUF exists under `/models/` (external Proxmox bind mount).

No list in `configuration.nix` needs editing: `models/default.nix` picks the
file up automatically. Do not reuse a model id — two files defining the same id
abort evaluation. The file name starts with the publisher's account
(`DavidAU`, `Unsloth`, `JetBrains`…): that is where its model card lives, and
the model card is where the family sampling values come from.

### Archiving a model

Move the file to `models/archived/`. It stays in the repository for reference
and is no longer served; no configuration edit is needed.

### Updating llama-cpp

```bash
nix run .#update-llama-cpp
```

This script queries the GitHub API for the latest llama.cpp release, prefetches
the source hash, forces the npm-deps hash mismatch to discover the new value,
and updates `llamacppVersion`, `llamacppHash` and `llamacppNpmHash` in place.
It requires a Nix host because it evaluates `pkg.npmDeps`.

## Sampling and filters

Sampling is set in two places, and they are not interchangeable:

- **`commonArgs` in the model's `cmd`** — server flags (`--temp`, `--top-k`,
  `--samplers`…): the default for every request that model serves.
- **`filters.setParamsByID`** — request parameters for one variant
  (`dry_multiplier`, `reasoning_budget`…), applied when the client id carries the
  suffix.

Nothing here can tune sampling by measuring speed: `llama-bench` has no sampler
flags, so a battery sees t/s and VRAM only. Whether a sampling change is good is
a question about output quality, judged outside this host.

### The chain

For each token the model scores its whole vocabulary, a chain of samplers
transforms or filters those scores, and one token is drawn. The order is the
chain, and it changes the result.

`--samplers` lists the names separated by `;`; `--sampler-seq` spells the same
list in single letters. They are two forms of one chain, not additions: the last
one given wins.

Default chain in llama.cpp 0.9.0 — `llama-server --help` is the source of truth,
re-check it after a version bump (the server README quotes an older list for
`/completion`; see `MEMORY.md`):

    penalties;dry;top_n_sigma;top_k;typ_p;top_p;min_p;xtc;temperature

Spark and Gemma 4 12B override it with
`top_k;top_p;min_p;temperature;dry;typ_p;xtc`: no `penalties` stage, and
temperature runs ahead of DRY. Both still pass `--repeat-penalty 1.1`, which in
that chain does nothing (see `MEMORY.md`).

`top_n_sigma` and `typ_p` sit in the default chain but do nothing at their
defaults, and the two chains written here leave them out. `--temp 0` is greedy:
deterministic and prone to loops. Otherwise `--seed` makes a run reproducible.

### Where the values come from

The per-family sampling values are the starting point, not a source of truth:
they come from the model card on Hugging Face, and the first token of the file name
is the publisher's account (`DavidAU`, `Unsloth`, `JetBrains`, …). Performance
depends on the hardware and the llama.cpp version, so re-check before trusting.

### What each sampler does

| Sampler | Flag | Effect | Cost |
|---|---|---|---|
| temperature | `--temp` | sharpens the scores below 1, flattens them above 1 | the global precision/variety knob |
| top-k | `--top-k` | keeps the K best candidates; 0 disables | fixed, ignores how sure the model is |
| top-p | `--top-p` | keeps the smallest set that adds up to probability p; 1.0 disables | adapts to confidence |
| min-p | `--min-p` | drops anything below p × the best candidate; 0 disables | adapts, and holds up better than top-p at high temperature |
| XTC | `--xtc-probability`, `--xtc-threshold` | with probability p removes the most likely candidates above the threshold (0.10 by default); off until p > 0 | creative writing |

`--grammar` and `--json-schema` are not samplers: they forbid the tokens that
would break the format. `--logit-bias` adds a fixed amount to named tokens.

### Repetition

The three penalties look at the last `--repeat-last-n` tokens (64 by default, 0
disables them) and act on single tokens, never on sequences.

- `--repeat-penalty` penalises the score of every token seen in the window.
  Binary and per token: it cannot tell a harmful repeat from a legitimate one —
  variable names, braces, quotes, JSON keys. 1.0 disables it.
- `--presence-penalty` subtracts a fixed amount from every token that already
  appeared, however often.
- `--frequency-penalty` subtracts in proportion to how often it appeared.

### DRY

DRY penalises repeated *sequences*. If the next token would continue a sequence
that already appeared, the penalty grows exponentially with the length of the
repeat — each token past `--dry-allowed-length` (2 by default) multiplies it —
and repeats shorter than that are free.

- `--dry-multiplier` strength; 0 disables DRY.
- `--dry-base` how fast the penalty grows; 1.75 by default.
- `--dry-allowed-length` repeats up to this length are free.
- `--dry-penalty-last-n` how far back it looks; 64 by default, 0 disables.

`--dry-sequence-breaker` is a trap: passing it **replaces** the default breakers
(newline, `:`, `"`, `*`) instead of adding to them, and `none` removes all of
them. Those defaults are what keep dialogue formatting and JSON keys from being
penalised.

Unlike the repetition penalties, DRY lets isolated repeated tokens through — the
ones code and JSON need — and reacts only when a stretch is being reproduced.

### Reasoning budget

A model that reasons writes a thinking block first. `reasoning_budget` caps it:
−1 unrestricted (the default), 0 no reasoning, N a token limit. When it runs out
the server forces the block closed and injects `reasoning_budget_message` before
the end-of-thinking tag: *budget forcing* is the server acting, not the model
deciding to stop.

It is not `max_tokens`/`n_predict`: that caps the whole output, thinking included,
and running out mid-thought truncates the answer. The budget caps only the
thinking and leaves room to answer.

`:instruct` turns reasoning off through the template (`chat_template_kwargs`),
not through the budget.

### Speculative decoding

A draft model proposes the next few tokens and the target checks them, so the
speedup depends on how many proposals survive. Here the draft is an MTP head
(`--spec-type draft-mtp` plus `-md`), and `--spec-draft-n-max` (3 by default) is
how many tokens it proposes per step.

`--spec-draft-sampling` decides how the draft picks: `greedy` (default) takes its
best token, `probabilistic` samples the draft and has the target verify it by
rejection sampling. Under `greedy` a proposal only survives if the target would
have drawn that same token, so the more random the target's sampling — high
temperature, XTC — the fewer proposals survive and the smaller the speedup.

`ngram*` spec types are banned until their cost is investigated: a draft n-gram
nucleus adds an index on top of the draft weights and VRAM, and the draft heads
used here (`draft-mtp`) are cheap enough that the acceleration is not worth the
cost in the majority of cases. Investigation is a pending task.