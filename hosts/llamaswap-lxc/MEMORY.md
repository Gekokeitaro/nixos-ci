# MEMORY.md — llamaswap-lxc

State of this host and what is still open. Mechanics live in `AGENTS.md`; what is
deployed on the host, in [`nixos-ci/MEMORY.md`](../../MEMORY.md).

Last updated: 2026-11-11.

## Sampling

- 15 of the 17 model files serve the default sampler chain. Only Spark X2.6 4B and
  Gemma 4 12B spell their own: `top_k;top_p;min_p;temperature;dry;typ_p;xtc`.
- **Open: `--repeat-penalty 1.1` is inert in both.** Their chain has no `penalties`
  stage, so the flag does nothing. Left as it is on purpose: adding the stage would
  change what two already-evaluated models generate. Decide with quality
  measurements, not by eye.
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
flag in `commonArgs` is what applies.

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

A checkpoint costs about half a MiB per 1k of context, so a longer `--ctx-size`
makes each one bigger and fills the same ~1.4 GiB ceiling sooner: at 16k the
climb is ~51 MiB per request and plateaus at turn 28, at 32k it is ~103 MiB and
plateaus at turn 14. The retained budget does not grow with the context; the
number of checkpoints kept shrinks.

Context checkpoints are the largest pure overhead found: they only save
re-processing when the prompt cache misses, and the default keeps 32 per slot.
The convention already in the model files, `--cache-ram 512 --ctx-checkpoints 4`,
is the right base. `Unsloth-Qwen3.5-9B` is missing it and runs at the default;
that is the one file to fix first.

`--ctx-size` is not the knob to cut: it is what the agentic use case needs. Bound
everything else first, then experiment upward while the process stays under the
16 GiB soft limit (20 GiB of RAM is the hard wall and OOMs the container).

## Open: spec type

- `ngram-mod` costs +59 MiB loaded and +123 MiB generating, constant to 49k of
  context: not a memory problem. The ban is lifted (see `AGENTS.md`); what is
  still unmeasured is its speedup in an agentic session, which belongs to a
  speculative-decoding benchmark.
- Two model files use it: `Prism-ML-Ternary-Bonsai-2-9B` (`ngram-mod`) and
  `Unsloth-gemma-4-E4B` (`ngram-mod,draft-mtp`). The combo pays the MTP stack
  (~608 MiB) and is correct: on novel text ngram has no match and MTP drafts.
