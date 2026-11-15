---
name: sampling
description: Changes what a model samples on the llama-swap host — the order of the sampler chain, `--temp`, `--top-k`, `--top-p`, `--min-p`, XTC, the DRY and repetition penalties, `reasoning_budget`, and whether a value belongs in `cmd` or in `filters` for one variant. Use when tuning repetition, loops, creativity, a cut-off thinking block, an inert `--repeat-penalty`, a `--samplers`/`--sampler-seq` list, or the `top_n_sigma`/`typ_p` stages — even when the user never says "sampling". Not for creating or archiving the entry (`model-files`), nor for measuring — the battery, the spec grid and the gates belong to `llama-bench-runner`.
---

# Sampling

Changes what a model serves: the chain in `commonArgs`, the per-variant values in
`filters.setParamsByID`.

Measured at llama.cpp 0.9.0. `llama-server --help` is the source of truth;
re-check it after a version bump.

## Gotchas

- `--dry-sequence-breaker` **replaces** the default breakers (newline, `:`, `"`,
  `*`) instead of adding to them, and `none` removes all of them.
- `--repeat-penalty 1.1` is inert in the chain Spark and Gemma 4 12B override: it
  has no `penalties` stage.
- `:instruct` turns reasoning off through `chat_template_kwargs`, not through
  `reasoning_budget`. Budget 0 is a different change.

## Where a value goes

Two places, and they are not interchangeable:

- **`commonArgs` in the model's `cmd`** — server flags (`--temp`, `--top-k`,
  `--samplers`…): the default for every request that model serves.
- **`filters.setParamsByID`** — request parameters for one variant
  (`dry_multiplier`, `reasoning_budget`…), applied when the client id carries the
  suffix.

Sampling cannot be tuned by measuring speed: `llama-bench` has no sampler flags,
so a battery sees t/s and VRAM only. A sampling change is judged on output
quality; the gate is CORE, owned by the workspace `AGENTS.md`.

## The chain

`--samplers` lists the names separated by `;`; `--sampler-seq` spells the same
list in single letters. They are two forms of one chain, not additions: the last
one given wins.

Default chain:

    penalties;dry;top_n_sigma;top_k;typ_p;top_p;min_p;xtc;temperature

Spark and Gemma 4 12B override it with
`top_k;top_p;min_p;temperature;dry;typ_p;xtc`: no `penalties` stage, and
temperature runs ahead of DRY.

`top_n_sigma` and `typ_p` sit in the default chain but do nothing at their
defaults, and the chains written here leave them out. `--temp 0` is greedy:
deterministic and prone to loops. Otherwise `--seed` makes a run reproducible.

## Where the values come from

The per-family values are a starting point, not a source of truth: they come from
the model card on Hugging Face, and the first token of the model file name is the
publisher's account. Hardware and the llama.cpp version move them, so re-check.

What is still open on this host is in
[`hosts/llamaswap-lxc/MEMORY.md`](../../hosts/llamaswap-lxc/MEMORY.md).

## Depth

- Read [`references/samplers.md`](references/samplers.md) before choosing between
  temperature, top-k, top-p, min-p and XTC, or when a format flag looks like a
  sampler.
- Read [`references/penalties.md`](references/penalties.md) before touching
  `--repeat-penalty`, `--presence-penalty`, `--frequency-penalty` or any
  `--dry-*` flag.
- Read [`references/reasoning-budget.md`](references/reasoning-budget.md) when you
  set `reasoning_budget` or work on a `:instruct` variant.
- Read [`references/speculative-decoding.md`](references/speculative-decoding.md)
  when you add or read a `--spec-*` flag.

## Changing a value

1. Decide which place the value belongs to: a server flag goes in `cmd`, a
   per-variant request parameter goes in `filters`.
2. Change one knob.
3. Run the evaluation and compare with that model's own baseline.
4. Quote the result with the variant and the `TEMP` it was measured at.
