---
name: sampling
description: Changes what a model samples on the llama-swap host — the order of the sampler chain, `--temp`, `--top-k`, `--top-p`, `--min-p`, XTC, the DRY and repetition penalties, `reasoning_budget`, and whether a value belongs in `cmd` or in `filters` for one variant. Use when tuning repetition, loops, creativity, a cut-off thinking block, an inert `--repeat-penalty`, a `--samplers`/`--sampler-seq` list, or the `top_n_sigma`/`typ_p` stages — even when the user never says "sampling". Not for creating or archiving the entry (`model-files`), nor for measuring — the battery, the spec grid and the gates belong to `llama-bench-runner`.
---

# Sampling

Changes what a model serves: the server flags in the `cmd` of the model file and
the per-variant values in `filters.setParamsByID`.

Measured at llama.cpp 0.9.0. `llama-server --help` is the source of truth;
re-check it after a version bump.

## Gotchas

- `--dry-sequence-breaker` **replaces** the default breakers (newline, `:`, `"`,
  `*`) instead of adding to them, and `none` removes all of them.
- `--repeat-penalty` is inert in a chain that has no `penalties` stage: a
  `--samplers` list that omits that stage makes the flag do nothing.
- `:instruct` turns reasoning off through `chat_template_kwargs`, not through
  `reasoning_budget`. Budget 0 is a different change. The `profiles.instruct`
  filter is sampling only and leaves reasoning on.

## Where a value goes

Two places, and they are not interchangeable:

- **`cmd` in the model file** — server flags (`--temp`, `--top-k`,
  `--samplers`…): the default for every request that model serves. A `let` named
  `commonCmd` in the file is only a shared string, not a second place: the value
  still reaches the server through `cmd`.
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

## Roles

The reference model serves one entry, one `cmd` and six request-level roles, so
moving between ids reloads nothing: `planner` (budget 6144, temperature 1.0),
`implementer` (0.6, no budget), `reviewer` (budget 4096, 0.6), `supervisor`
(budget 4096, 0.7), `integrator` (0.7, no budget, resolves a merge) and
`instruct` (0.7, the only one with the thinking block closed). The table itself
is `modelLib.profiles.roles` in `models/lib/default.nix`; read it there instead
of copying these values.

`top_k`, `top_p` and `min_p` are equal across every role. The speculative preset
lives in the `cmd` and is shared, so a role that changed the sampling of drafted
tokens would invalidate the measurement for that role. That is the reason, not
symmetry.

`instruct` closes the thinking block with
`chat_template_kwargs.enable_thinking = false` on the **request**, and that was
verified rather than assumed: on one prompt the bare id spent 1393 characters in
`reasoning_content` and answered nothing in 400 tokens, while `:instruct`
produced 0 reasoning characters and 1521 characters of answer.

**`reasoning_effort` is not a universal knob.** A chat template either enumerates its values
and raises on anything else, or ignores the field — there is no middle, and which one it is
belongs to the GGUF, not the family. Ask the template, with no GPU involved:
`reasoning-efforts.sh /models/<model.gguf` (in `llama-bench-runner`) prints the accepted set
and its default. The set does not follow the family — measured 2026-11-20: the **27B base
quants** declare `{xhigh, medium, low}` defaulting to `xhigh`, the **27B Turbo-Brilliance
fine-tune of the same family declares nothing**, and `Spark-X2.6-4B` declares `{high, low}`
defaulting to `high`. The three entries this workspace leans on — the reference
`Qwen3.5-9B-UD`, the 35B and the served 27B fine-tune — **do not read the field at all**. The
sweep is `llama-bench-runner/measurements/reasoning-effort-templates.md`. Two consequences:
the field can bound loops on a model that implements it, and **a gateway in front can rewrite
it** — OmniRoute clamps an unlisted value to the nearest accepted tier and retries, so the
model receives `high` although the client asked for `medium`. Trust the gateway's own
`… | effort=<value>` log line over the flag that was passed.

**It is a lever, not an axis — decided 2026-11-20.** The effort is *not* swept per role: it is
offered for the tests that run into the ceiling, and only there. Being a request field, it can
travel in `filters.setParamsByID` exactly like `reasoning_budget`, so a client asks for the
cheaper tier through a variant (`:low`) and no second `cmd` is needed. `xhigh` is the most
timeout-prone tier and its quality does not buy back a 900 s ceiling; what the client sends by
default is `medium`, which the 27B accepts and Spark rejects with a 400, so the gateway
clamps it up to `high`.

**Order of the loop levers — decided 2026-11-20, conditional on the measurement below.**
The progression over the tiers is **`medium` → `low` → `high` → `xhigh`**, filtered by what the
template accepts: the two cheap tiers are the preferred ones, and `high`/`xhigh` are the
exception, taken only when quality forces them. **DRY and `reasoning_budget` attach to that
expensive end**, not to the cheap one: they are what keeps `high` or `xhigh` inside a 900 s
ceiling when the quality demands the tier. And where the template implements the effort,
**the effort comes before both**: it is the model's own instruction, injected by its template,
so it changes the plan the model follows, while DRY penalises repeated sequences and the
budget truncates the thinking block by force — external corrections to a model that is already
misbehaving.

Applied to what this host serves: **Spark** accepts `{high, low}`, so its progression starts at
`low` and only escalates to `high` with DRY or a budget behind it; the **27B base quants**
accept `{xhigh, medium, low}`, so they start at `medium`, fall to `low`, and reach `xhigh`
only with that support. The **reference, the 35B and the served 27B fine-tune read nothing**,
so for those three the effort is not a lever at all and DRY/budget are all there is.

DRY 0 and `presence_penalty` 0 are a **correction of this GGUF** (copy-fidelity
round of 2026-11-16), not role axes: moving them per role would confound a role
with the correction. XTC is a roleplay sampler and stays out.

DRY and a reasoning budget are **correctives of a role, never variants of their
own**: `:dry` and `:dry-budget-*` were retired on 2026-11-19, and a measurement
that asks for a different value composes it into the one role it applies to
(`profiles.roles.reviewer // modelLib.dryParams`) and re-measures that role.

`profiles.instruct` is sampling only, with reasoning left on; the `instruct`
**role** takes the template trait instead. Do not treat the two as one value.

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
