# Per-family sampling, from the cards

What the publisher recommends, and where this host departs from it. It is a starting point, not
evidence: the card describes the family, the measurement describes the GGUF.

**Archive, not research.** The research happens on the web and is dated; this file keeps what was
collected so it is not looked up twice. When a value here is older than the model or the quant it
describes, the skill's first step is to go back to the card and to the users outside the repo.

## Qwen 3.5 / 3.6 — the reference and the 35B

Four presets, straight from the Qwen card, and the last one is the card's own oddity:

| mode | temp | top_p | top_k | min_p | presence | repeat |
|---|---|---|---|---|---|---|
| thinking, general | **1.0** | 0.95 | 20 | 0.0 | 1.5 | 1.0 |
| thinking, precise coding | **0.6** | 0.95 | 20 | 0.0 | **0.0** | 1.0 |
| non-thinking, general | **0.7** | **0.8** | 20 | 0.0 | 1.5 | 1.0 |
| non-thinking, reasoning | 1.0 | 0.95 | 20 | 0.0 | 1.5 | 1.0 |

`presence_penalty` may be raised toward 2 "to reduce endless repetitions", with the card's own
warning that a high value causes language mixing. **The 27B of the 3.6 family takes
`presence 0.0` in thinking-general where the 35B-A3B takes `1.5`** — the family is not uniform, and
the card says so.

This host's base profiles are exactly these four, which is why `profiles.thinking`,
`profiles.coding` and `profiles.instruct` look the way they do.

## Gemma 4 — 12B and E4B

The card gives **one** configuration for every use case:

```
temperature = 1.0   top_p = 0.95   top_k = 64
```

**The host does not serve that.** Both Gemma 4 entries carry `--temp .6 --top-p 0.95 --top-k 20`,
which is Qwen's coding preset, and the 12B also spells a `--samplers` chain of its own. Nothing
measured says the card is better here - but a family served at another family's preset is a
deviation nobody chose deliberately, and it is the first thing to test for these two.

**Web research, 2026-11-23 — four independent sources agree on the card's trio.** Google's model
card and its best-practices page (`gemma.ai/models/gemma-4/model-card`,
`raw.githubusercontent.com/google-gemma/docs/main/docs/get-started/best-practices.md`), Unsloth's
run guide (`unsloth.ai/docs/models/gemma-4`), Ollama's library page (`ollama.com/library/gemma4:12b`,
whose `params` read exactly `{"temperature": 1, "top_k": 64, "top_p": 0.95}`) and a local-run guide
(`7minai.com/how-to-run-gemma-4-12b-locally`, 2026-06-04) all print `temperature 1.0, top_p 0.95,
top_k 64` as **the** configuration, "across all use cases", and the last one warns that leaving
`0.7` or dropping `top_k` makes the model look worse than it is.

Two findings from the same pass that the host has not applied:

- **Thinking is opt-in through the system prompt.** It is triggered by the `<|think|>` token at the
  start of the system prompt, and turned off by removing it — not by a sampler. Our base entries
  never add it; `:instruct` uses `chat_template_kwargs.enable_thinking=false`.
- **No thinking blocks in history.** The card says previous turns' thoughts must not be replayed
  (tool-call turns excepted), which the harness's session handling does not currently distinguish.

## LFM3 — 1.7B

Two regimes, and the near-greedy one is for exactly our kind of work:

| use | temp | top_p | top_k | repeat |
|---|---|---|---|---|
| general: chat, tool use, **agents, coding** | **0.1** | — | **50** | **1.1** |
| math / STEM | 1.0 | 0.95 | 20 | — |

The card's own note: small agentic models are more sensitive to sampling noise than frontier
ones. This host serves no LFM at all today; the value is here for when one is added.

## Mellum — 12B A2.5B

JetBrains scored its non-agentic evaluations with **greedy decoding** — `temp 0`. Greedy is
deterministic and prone to loops, so it is a benchmark setting, not necessarily a serving one;
for agentic work the Qwen non-thinking preset is the closer analogue. No card values beyond that.

## Spark X2.6 — 4B

No publisher recommendation found. The entry serves `--temp .6 --top-p .95 --top-k 20`, and its
template accepts `reasoning_effort` (`high` default, `low`), which is the model's own idea of how
to bound thinking. Nothing to inherit: measure it.

## What this means for the roles

The roles are not "families", so the mapping is by *task*, not by model:

| role | mode | nearest card preset |
|---|---|---|
| `planner` | thinking, general (a plan explores) | Qwen thinking-general, or Gemma 4's single preset |
| `implementer` | thinking, precise coding | Qwen thinking-coding (`presence 0`) |
| `reviewer` | thinking, precise coding at low temperature | Qwen thinking-coding |
| `supervisor` | non-thinking, general (dispatch, triage) | Qwen non-thinking-general |
| `integrator` | non-thinking, general | Qwen non-thinking-general |
| `instruct` | non-thinking, reasoning | Qwen non-thinking-reasoning |

Where a family publishes **one** preset for everything (Gemma 4), the role split is our
inference, not the vendor's — and it should be measured rather than assumed.
