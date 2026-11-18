# MEMORY.md — llamaswap-lxc

State of this host and what is still open. Mechanics live in
[`../../skills/sampling/SKILL.md`](../../skills/sampling/SKILL.md) and
[`../../skills/model-files/SKILL.md`](../../skills/model-files/SKILL.md); what is
deployed on the host, in [`../../MEMORY.md`](../../MEMORY.md).

Last updated: 2026-11-18.

## Sampling

- 14 of the 16 model files serve the default sampler chain. Only Spark X2.6 4B and
  Gemma 4 12B spell their own: `top_k;top_p;min_p;temperature;dry;typ_p;xtc`.
- **Open: the `:dry-budget-4000*` variants set `reasoning_budget = 4096`.** The
  suffix says 4000. Rename one or the other deliberately, not by accident.
- **Open: in both custom chains temperature runs ahead of DRY**, unlike the default
  chain. Unclear whether that is intended; the order changes the result.
- **Open: how to disable XTC.** `llama-server --help` prints `1.0 = disabled` for
  `--xtc-threshold`; the server README says anything above `0.5` disables it. XTC is
  off while `--xtc-probability` stays at 0, so nothing depends on it today.

**Confirmed on the running server, 2026-11-11:** `GET /props` of a loaded model
reports the chain given by `--samplers`, not the request default that the server
README lists for `/completion` (which omits `penalties` and `top_n_sigma`). So the
flag in the model's `cmd` is what applies.

Per-model knob values are in each model's `.nix`, where they are applied.

## Context

- **`--ctx-size` starts at 32k** and is the most important parameter of the host:
  the context is the product of the agentic use case, so you always start there, and
  you can raise it only while total VRAM stays within the 16 GB ceiling (model plus
  KV plus overhead).
- **Samplers per family are the starting point, not a source of truth.** The values
  for each family come from the model card on Hugging Face, and the first token of
  the file name is the publisher's account (`DavidAU`, `Unsloth`, `JetBrains`, …),
  which is the convention for building the `.nix`. Performance depends on the
  hardware and the llama.cpp version, so the family values are a starting point to
  tune, not a fixed truth.

## Memory budget

Measured on `Unsloth-Qwen3.5-9B` at llama.cpp 0.9.0, one slot, 16k of context:

| Setting | Cost |
|---|---|
| `--ctx-checkpoints` default 32 | ~1.4 GiB, plateauing after ~28 checkpoints |
| `--ctx-checkpoints 4` | ~70 MiB |
| `--ctx-checkpoints 0` | nothing |
| `--cache-ram 0` vs default | ~100 MiB less at the same depth |

A checkpoint costs about 3 MiB per 1k of context, so a longer `--ctx-size`
makes each one bigger and fills the same ~1.4 GiB ceiling sooner: at 16k the
climb is ~51 MiB per request and plateaus at turn 28, at 32k it is ~103 MiB and
plateaus at turn 14. The retained budget does not grow with the context; the
number of checkpoints kept shrinks.

Context checkpoints are the largest pure overhead found: they only save
re-processing when the prompt cache misses, and the default keeps 32 per slot.
Six files carry `--cache-ram 512 --ctx-checkpoints 4`, three run
`--cache-ram 0` instead, and seven carry neither flag: those seven are the first
thing to check when a model is short on memory.

`--ctx-size` is not the knob to cut: it is what the agentic use case needs. Bound
everything else first, then experiment upward while the process stays under the
16 GiB soft limit (20 GiB of RAM is the hard wall and OOMs the container).

## The reference model's six ids

`models/Unsloth-Qwen3.5-9B-UD-Q4_K_XL.nix` serves one entry and one `cmd` under six
client ids: the bare `Unsloth Qwen3.5 9B UD Q4_K_XL`, which is the measured default
and the control of 2026-11-18, plus `:planner`, `:implementer`, `:reviewer`,
`:supervisor` and `:integrator`. The five roles are request-level values
(`modelLib.profiles.roles`), so moving between two of the six reloads nothing; the
axis each role moves, and why, is commented in `models/lib/default.nix`. This entry
no longer serves `:coding` or `:instruct`.

Refresh `pi`'s catalog (`pi update --models`, `/omni sync`) before any run: an id
absent from the snapshot cannot be addressed, and the snapshot expires after 60
minutes. Measuring the roles one at a time is session 8 of the workspace `PLAN.md`.

## Pending: the reference model's preset is committed, not deployed

- The tree serves `Unsloth Qwen3.5 9B UD Q4_K_XL` with one MTP implementation:
  `--spec-type draft-mtp,ngram-mod --spec-draft-n-max 1
  --spec-ngram-mod-n-match 24 --spec-ngram-mod-n-min 32 --spec-ngram-mod-n-max 64`,
  and `--ctx-size 196608`, the largest 32k multiple under the measured 217088
  ceiling. The commit is local; nothing of it is on `nixos-llamaswap-rocm` yet.
- The gate reference is the control CORE at the old configuration — 65536 of
  context and `draft-mtp` with `n-max 2` — which was still running when these
  numbers were committed. A deploy during that run invalidates it, so the deploy
  comes after the run ends and its result is read.
- The fixed chat template no longer comes from the `/models/templates/` checkout:
  a pinned `fetchurl` of the same bytes (28,234 B, same sha256) takes its place.
  That changes no behaviour, so it needs no CORE of its own.

## Open: spec type

- `ngram-mod` costs +59 MiB loaded and +123 MiB generating, constant to 49k of
  context: not a memory problem. The ban is lifted (see
  [`speculative-decoding.md`](../../skills/sampling/references/speculative-decoding.md));
  what is still unmeasured is its speedup in an agentic session, which belongs to
  a speculative-decoding benchmark.
- Two model files use it: `Prism-ML-Ternary-Bonsai-2-9B` (`ngram-mod`) and
  `Unsloth-gemma-4-E4B` (`ngram-mod,draft-mtp`). The combo pays the MTP stack
  (~608 MiB) and is correct: on novel text ngram has no match and MTP drafts.
