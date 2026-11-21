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
