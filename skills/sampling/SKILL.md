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
What each card actually says, and where this host departs from it:
[`references/per-family.md`](references/per-family.md).

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
offered for the tests that run into the ceiling, and only there. **It travels from the client**
— `pi`'s thinking level, `PI_EXTRA='--thinking low'` in the harness — and not from a variant of
the model: no `:low` id is created, and the factory is the place that will eventually send it.
Consequences of that choice: the model host records nothing about it, so the run's `--note` and
the gateway's `… | effort=<value>` line are the only evidence, and two tiers of the same id
share one client id, so the folder is quarantined between them.

**Order of the loop levers — decided 2026-11-20, bottom-up.** The progression over the tiers is
**`medium` → `low` → `high` → `xhigh`**, filtered by what the template accepts, and the
direction is **up only on evidence**: start at the cheapest preferred tier, and climb only when
it loses a test the tier below passed. The reason is not taste — **a tier that times out
returns `score=none`, and `none` is not a zero**: it is a row that cannot answer the quality
question, so a top-down sweep spends hours of GPU on ceilings and learns nothing. A finished
row at `low` is worth more than a `TIMEOUT` at `xhigh`.

**The cheap tier was measured on 2026-11-20 and did not brake the loop.** Spark at
`reasoning_effort=low` — the gateway log confirms `effort=low`, so the value reached llama.cpp —
returned **0 of 9 on `t04`/`t05`/`t12`, every row at the 900 s ceiling**, the same 0/9 the
default `high` gives on those tests. The effort is a *thinking* instruction, and those rows fail
while writing: the captured server log shows a row producing a **valid file at 691 s** and still
generating to the ceiling. When the loop is in the writing, the brake is the budget and its
forced message, not the tier.

**DRY and `reasoning_budget` attach to the expensive end**, not to the cheap one: they are what
keeps `high` or `xhigh` inside a 900 s ceiling when the quality forces the tier. Where the
template implements the effort, **the effort comes before both**: it is the model's own
instruction, injected by its template, so it changes the plan the model follows, while DRY
penalises repeated sequences and the budget truncates the thinking block by force.

**And the climb is judged blind where the evaluator cannot see.** A cheap tier that keeps the
`OK` count can still ship a worse artefact: on the coarse tests (`t10`, `t15-B`, `t08`) the
checks do not separate them, so a tier that is about to be adopted goes through the frozen
rubric and the blind pair before it is quoted.

Applied to what this host serves: **Spark** accepts `{high, low}`, so it starts at `low` and
escalates to `high` only if `low` loses a test — with DRY or a budget behind it. The **27B base
quants** accept `{xhigh, medium, low}` — **no `high` at all**, so the ladder has three rungs
and no middle step — and `xhigh` is reported as that family's most effective tier, which makes
it a contender rather than a last resort: `medium` first, `low` as the cheaper fallback,
`xhigh` as the serious candidate **with a budget behind it**, because that is the tier most
likely to spend 900 s. The **reference and the 35B read nothing**, so for those the effort is not
a lever at all and DRY/budget are all there is. On the 27B the field is **already served** by
two entries — `Ukisai Swift 1.5 Qwen3.8 27B … mtp` and `Prism ML Ternary Bonsai 2 27B Q2_0` —
while the third, `David AU Qwen3.8 27B TBrill … mtp`, reads nothing; pick the entry, not the
size class.

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
