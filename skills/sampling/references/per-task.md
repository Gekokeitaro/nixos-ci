# Per-task sampling, from outside the cards

The cards say what a *model* likes; the field says what a *task* needs, and the two disagree by
a factor of three. Both are right in their domain.

## What the field converges on

| task | temperature | truncation | source |
|---|---|---|---|
| code generation | **0.0-0.2** | top_p 0.95 or min_p 0.1 | three independent guides agree; "syntax requires precision" |
| tool calls, JSON, routing, extraction | **0.0-0.2** | top_p 0.95 | agent guides: deterministic calls for reliable agents |
| reasoning and analysis | 0.3-0.5 | top_p 0.95 | same guides |
| general chat | 0.5-1.0 | top_p 0.9 / min_p 0.05 | the broad middle |
| creative | 0.7-1.2 | top_p 0.95 | not our work |

Two hard rules the guides repeat:

- **`temp 0` makes everything else decoration.** At greedy, top_k, top_p and the penalties have
  no effect — "you've inadvertently zeroed them out". A low temperature and a high penalty fight
  each other, and the penalty wins vocabulary at random.
- **The truncation has to be one of `top_p` or `top_k`, understood**, not both set to tight
  values: the more restrictive one dominates and the other is dead weight.

llama.cpp's own defaults, for when nothing is sent: **temp 0.8, top_p 0.9, min_p 0.1, top_k 40,
repeat 1.0**. An unfiltered id serves exactly that.

## The 2026 shift, which this host already met

Frontier reasoning models stopped accepting sampling: they take an effort level and ignore
temperature. The same year, this host found `reasoning_effort` implemented in only two of its
templates, and a gateway rewriting it. Sampling and effort are converging on the same question —
how much to think — from opposite ends.

## What the users say, and it contradicts the table above

End users on local models report the opposite of "cold for code", with a mechanism:

- **"Ultra low temps make your model stupid at coding"** (r/LocalLLaMA): a sweep at 0, 0.25, 0.5,
  0.75 and 1.0 found the lowest settings worse, and the post's advice is "check the card for
  whatever model you run before copying a benchmark's sampler settings".
- **Gemma 4 works best at high temperature for coding** (Unsloth GGUF discussion, 26B-A4B): at
  the card's 1.0/0.95/64 against 0.8, 0.6 and 0.3, "each step down made it worse". That is the
  card beating the task rule on the very model the rule would have changed.
- **"0.6 for precise coding is a bit on the high side"** and "temperature 1.0 for reasoning seems
  quite high" (r/LocalLLaMA, on the Qwen card) — the cards are not gospel either; they are a
  starting point that users argue with in both directions.

The mechanism that reconciles it: at very low temperature the model cannot leave a bad local
choice, so it commits to the first plausible line and stays there. Determinism protects a task
with one right answer; it hurts a model that has to explore towards one.

### And one claim worth testing that we have never tested

> "Everyone supplies parameters but nobody supplies the correct sampler chain, trusting
> llama.cpp's default one. The right way: `--samplers "temperature;top_p;top_k"`."

For Gemma 4 that puts **temperature first**, then the filters — while our Gemma entries run
`top_k;top_p;min_p;temperature;dry;typ_p;xtc`, temperature near the end. The order is a lever
nobody here has measured, on a family whose card is explicit about its parameters.

Two more community positions, cheap to test and both unmeasured here:

- **`min_p` over `top_p`/`top_k`**: the Min-P paper (ICLR 2025 oral) reports 0.05-0.1 beating
  top_p at high temperature. Every profile here runs `min_p 0.0`, disabled.
- **One filter, understood**: `top_p` and `top_k` both tight is a conflict, not a safeguard.

**So the experiment changes.** Not "cold against the card" — the users already answered that. The
open questions are the **chain order** (temperature first, as the community says and Gemma's card
implies) and **`min_p` at 0.05-0.1 instead of 0**, both on the Gemma entries, both judged by
CORE rather than by feel.

## Where our roles sit, and the gap

| role | the field says | our profile | gap |
|---|---|---|---|
| `implementer` | **0.0-0.2** | 0.6 | card's coding preset, not the field's |
| `reviewer` | **0.0-0.2** | 0.6 | same |
| `supervisor` | **0.0-0.2** | 0.7 | routing wants determinism |
| `integrator` | **0.0-0.2** | 0.7 | a merge is a structured choice |
| `planner` | 0.3-0.5 | 1.0 | card's thinking-general |
| `instruct` | 0.5-1.0 | 0.7 | the only one inside the band |

**Every role but `instruct` is warmer than the task literature recommends**, because the profiles
were derived from the model cards, and a card is tuned for chat and benchmarks, not for an agent
that must emit the same JSON twice.

That is one experiment, not six: `implementer` at `temp 0.2` against its 0.6 baseline, on its own
test group. If the colder setting keeps the rows it passes, the profiles should move toward the
task and away from the card; if it loses them, the card wins and we have learned where the line
is.
