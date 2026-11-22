# Sampler candidates, and what each would prove

Mechanics first, because they decide which experiments are even distinguishable.

## What each stage does

| stage | what it keeps | adapts to | notes |
|---|---|---|---|
| `penalties` | nothing; it **rescales** logits of tokens already seen (repeat / presence / frequency) | the history | flat, not sequence-aware |
| `dry` | nothing; it **rescales** repeated *sequences*, growing with length | the history | 0 disables; our roles run `dry_multiplier 0` |
| `top_n_sigma` | tokens within n σ of the max logit | the spread | −1 disables; in the default chain, inert at its default |
| `top_k` | the k highest | nothing | fixed count: on a flat distribution it keeps the same number anyway |
| `typ_p` | tokens whose information content is near the entropy | the shape | 1.0 disables; in the chain, inert at its default |
| `top_p` | the smallest set holding p of the mass | the shape | at low temperature it barely cuts; at high temperature it keeps a lot |
| `min_p` | tokens at least `min_p × p_max` | **the top token's confidence** | the only cutoff that scales with how sure the model is |
| `xtc` | **removes the most probable token(s)**, with a probability | nothing | roleplay; after the cutoffs it can drop the best survivor |
| `temperature` | nothing; it **reshapes** what survived, then samples | — | runs **last** |

Two consequences worth writing down:

- **Temperature runs last**, so every cutoff sees the *un-tempered* distribution. Reordering it
  first (as the community recommends for Gemma) changes which tokens the filters keep whenever
  the temperature is not 1.0 — at 1.0 the order is irrelevant. Our Gemma entries run `.6`, so for
  them the order is load-bearing.
- **`temp 0` zeroes the rest of the chain.** Greedy ignores every cutoff, so a "deterministic"
  configuration is not tuning the samplers at all.

## The candidates

Ordered by what each would prove per row of GPU spent.

### 1. The 35B's bare id, pinned to its card (12 rows, ~20 min)

`default = profiles.thinking` — `temp 1.0, top_p 0.95, top_k 20, min_p 0, presence 1.5`. Its
CORE and its `cross` ran on llama.cpp's defaults (`0.8 / 0.95 / 0.05 / 40`), which nobody chose.
**Proves:** whether the `cross` wobble (12/12 → 9/12 → 11/12) was the sampler. Same 12 rows, one
line of config. **Result 2026-11-22: 11/12 on the pin, and 11/12 on a repeat of the no-filter
config**, so the wobble is repetition noise on `t07`; no gain, no regression, the pin stands.

### 2. `repeat_penalty 1.05` on the implementer (its own group, 30 rows)

The card says 1.0; every practitioner's coder macro says **1.05**. One number, no other change.
**Proves:** whether repetition is costing rows the model nearly passes — `t02` scored 11-13/14
three times and still failed, and `t16`/`t01` are near misses. **Result 2026-11-22: 18/30
against 11/30, no row lost** (`t02` 2/3, `t04` 1/3, `t16` and `t03`/`t06` clean); kept, and it
is the implementer's baseline for candidate 3.

### 3. `min_p 0.05` with `top_p 1.0` and `top_k 0` (one role group)

The "min_p only" style: temperature plus one relative cutoff, everything else disabled. **Proves:**
whether the adaptive cutoff beats a fixed `top_k 20` on the tests where the model loops — it is the
only cutoff that tightens when the model is confident and opens when it is not.

### 4. Gemma, card against host (triage, k=1, both configs)

Card is `temp 1.0, top_p 0.95, top_k 64` and one preset for everything; the host serves
`.6 / .95 / 20` with a chain of its own. **Proves:** whether Google's numbers survive contact with
our tests. Cheapest form is `--triage` on both — never a baseline, but enough to see whether one
configuration is obviously worse. A full CORE first would cost three hours at 9.5 t/s before
answering a question a triage answers in one.

## Not worth a candidate

- **XTC** after the cutoffs, on a role that must emit the same JSON twice: it removes the most
  probable token on purpose.
- **`typ_p` and `top_n_sigma`**: inert at their defaults, and the chains here leave them out.
- **`temp 0`**: it makes every other candidate unmeasurable.
