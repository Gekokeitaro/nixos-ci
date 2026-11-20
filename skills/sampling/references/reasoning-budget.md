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

