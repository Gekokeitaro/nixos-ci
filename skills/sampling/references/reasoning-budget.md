# Reasoning budget

A model that reasons writes a thinking block first. `reasoning_budget` caps it:
−1 unrestricted (the default), 0 no reasoning, N a token limit. When it runs out
the server forces the block closed and injects `reasoning_budget_message` before
the end-of-thinking tag: *budget forcing* is the server acting, not the model
deciding to stop.

It is not `max_tokens`/`n_predict`: that caps the whole output, thinking included,
and running out mid-thought truncates the answer. The budget caps only the
thinking and leaves room to answer.

`instruct` turns reasoning off through the template (`chat_template_kwargs`),
not through the budget.

## Is the message cosmetic? No — the model reads it

The budget is a **sampler** (`common/reasoning-budget.h` in llama.cpp), and what it does at
expiry is stated in its own comment:

```
// FORCING: forces forced_tokens token-by-token (all other logits -> -inf)
// forced_tokens - token sequence forced when budget expires
enum common_reasoning_budget_state {
    REASONING_BUDGET_FORCING,      // forcing budget message + end sequence
    ...
```

So `reasoning_budget_message` is tokenised and **forced into the generation**, one token at a
time with every other logit at −inf, followed by the forced end-of-thinking sequence. Those are
*generated* tokens: they enter the sequence, therefore the context, and the model continues the
answer **with that text behind it**, as if it had written it. It is an instruction the model
attends to, not a label for the reader. `--reasoning-budget-message` documents it as "message
injected before the end-of-thinking tag when reasoning budget is exhausted (default: none)", so
without one the forced sequence is the closing tag alone.

Two consequences: the wording is part of the behaviour, and it costs tokens like any other
output — ten or fifteen, which is nothing against the thousands it ends.

## The value, decided 2026-11-20: **6144**

The reasoning blocks measured on the rows that burned the ceiling averaged **5 875 tokens**
(6 085, 4 945, 11 456, 3 066, 3 823), so 6144 covers the mean with a 5 % margin. What decides it
though is the clock, not the mean: a budget is only useful if it ends the thinking **while there
is still time to write**. At Spark's 13.5 t/s, 6144 tokens is ~455 s of a 900 s ceiling, leaving
~445 s; 8192 would leave ~293 s and covers the outlier; **12288 is useless on Spark** — 910 s of
thinking over a 900 s ceiling is the same as no budget. The general form is
`budget ≈ t/s × (900 − 300)`, and it is per GGUF.


## The key is `reasoning_budget_tokens`, and the short one is ignored

Measured 2026-11-26 against the served 27B, request-level, same prompt:

| field sent | thinking block | forced message |
|---|---:|---|
| nothing | 1 270 chars (~317 tok) | no |
| `reasoning_budget: 600` | 3 501 chars (~875 tok) | **no** |
| **`reasoning_budget_tokens: 600`** | 2 574 chars (~643 tok) | **yes** |

The server reads the long name and only the long name. At this host's commit
(build `b11960`, `8642541`), `tools/server/server-common.cpp` does:

```cpp
int reasoning_budget = json_value(body, "reasoning_budget_tokens", opt.reasoning_budget);
```

So a request carrying `reasoning_budget` — which is what `mkRoles` sent until 2026-11-26 — is a
request with **no budget at all**: the sampler is never told a number, nothing forces the close, and
the thinking block runs until `max_tokens`, the harness timeout, or the model's own loop. That is
why no role budget ever braked anything on any model, and why `/props` never shows the field: the
defaults carry no budget, and the value only exists per request.

`reasoning_budget_message` is correct as it stands; the message is what gets forced in, token by
token, once the budget expires. The start and end tags come from the session's own thinking
delimiters, which is why `--reasoning-format` has to be right for the parser to find them.

**How to check it without a deploy**: send a prompt that thinks long with
`reasoning_budget_tokens: 600` and `reasoning_budget_message` set; the block must end near 600
tokens with that message as its last thought. A response that thinks straight past the number is a
budget that did not land.
