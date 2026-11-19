# MEMORY.md — llamaswap-lxc

State of this host and what is still open. Mechanics live in
[`../../skills/sampling/SKILL.md`](../../skills/sampling/SKILL.md) and
[`../../skills/model-files/SKILL.md`](../../skills/model-files/SKILL.md); what is
deployed on the host, in [`../../MEMORY.md`](../../MEMORY.md).

Last updated: 2026-11-19.

## Variants

- **`:dry` and `:dry-budget-*` are retired (2026-11-19).** DRY and a reasoning budget are
  correctives of a role — `modelLib.profiles.roles.supervisor // modelLib.dryParams` — not
  variants of their own: seven ids per model carried two knobs that every role already
  decides for itself. The last served ones were Spark's, and their ids are gone with this
  deploy. `modelLib.dryParams` stays as the fragment; the labels 4000/6144 do not, because a
  label existed to avoid renaming a client id that no longer exists.

## Spark X2.6 4B, served from 2026-11-19

- Deployed after its own battery: `--ctx-size 196608` (ceiling 262144 with 162 MiB of
  margin, the policy cap; 192k buys the margin back), `-b 256 -ub 128 -ctk/-ctv f16`
  (re-measured at the served thread default: pp512 411, pp4096 295 - the best pair),
  chain left to llama.cpp's default order, `--temp .6 --top-p .95 --top-k 20`.
- **No reasoning budget.** A 526 s `ERR_API` on 2026-11-19 looked like an unbounded
  thinking block and was the gateway: the same row on the same cmd answered in 122 s once
  OmniRoute was healthy. The server default (-1) stands until something measures a loop.
- The six factory roles are served (`:planner`, `:implementer`, `:reviewer`,
  `:supervisor`, `:integrator`, `:instruct`), generic from `modelLib.profiles.roles`.
  `:instruct` changed meaning here: it used to be `noThink` alone at the `cmd`'s 0.6 and
  is now the library's role, same closed thinking block at 0.7.

## Sampling

- 15 of the 16 model files serve the default sampler chain. Only Gemma 4 12B spells its
  own (`top_k;top_p;min_p;temperature;dry;typ_p;xtc`); **Spark dropped its list on
  2026-11-19** and now uses the default order, with DRY travelling as a role's corrective.
- **Open: in the custom chain temperature runs ahead of DRY**, unlike the default
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

## The reference model's seven ids

`models/Unsloth-Qwen3.5-9B-UD-Q4_K_XL.nix` serves one entry and one `cmd` under seven
client ids: the bare `Unsloth Qwen3.5 9B UD Q4_K_XL`, which is the measured default
and the control of 2026-11-18, plus `:planner`, `:implementer`, `:reviewer`,
`:supervisor`, `:integrator` and `:instruct`. The six roles are request-level values
(`modelLib.profiles.roles`), so moving between two of the seven reloads nothing; the
trait or axis each role carries, and why, is commented in `models/lib/default.nix`.
`instruct` is the only one that closes the thinking block, through
`chat_template_kwargs.enable_thinking = false`. It is a general variant, not a factory
stage: its proposed suite — extraction, triage and edition tests plus `annex`, judged on
hits and median seconds per turn — lives as pending item 1 in `ai-tests/MEMORY.md`.

**Open: `enable_thinking` as a request parameter has not been read back.** It is
documented in llama.cpp 1.0.0 and three model files already carry the `noThink`
filter, but the only form this repo has put through a running server is the flag,
and Gemma's instruct entry sets it to `true` there. The first request against
`:instruct` must show in its own output that the thinking block is really closed;
if it is not, the fallback is a `cmd` flag, which would mean a second entry.

Refresh `pi`'s catalog (`pi update --models`, `/omni sync`) before any run: an id
absent from the snapshot cannot be addressed, and the snapshot expires after 60
minutes. Measuring the roles one at a time is session 8 of the workspace `PLAN.md`.

## The reference model's preset: deployed and gated

- The host serves `Unsloth Qwen3.5 9B UD Q4_K_XL` with one MTP implementation:
  `--spec-type draft-mtp,ngram-mod --spec-draft-n-max 1
  --spec-ngram-mod-n-match 24 --spec-ngram-mod-n-min 32 --spec-ngram-mod-n-max 64`,
  and `--ctx-size 163840` — a multiple of 32k, chosen for margin (see below).
- **Deployed and gated 2026-11-18.** The gate CORE `-k 3` gave 27 `OK` / 44 `FAIL` /
  4 `TIMEOUT` against the control's 28 / 39 / 8 (median 102 s against 105 s): inside the
  tie band, no test the control passed went to zero, `t03` and `t10` newly pass.
- **Why 160k and not 192k.** The measured ceiling is 217088 with `mtp n-max 2` and
  196608 with the candidate, but under `spec-bench` load the candidate peaks at
  14292 MiB against an allowance of 14336 at 192k: 44 MiB, which is luck, not margin.
  160k buys about a gigabyte back for a 17 % narrower window.
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
