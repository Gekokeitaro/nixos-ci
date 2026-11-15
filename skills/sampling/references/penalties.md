# Penalties and DRY

Defaults measured at llama.cpp 0.9.0.

## Repetition

The three penalties look at the last `--repeat-last-n` tokens (64 by default, 0
disables them) and act on single tokens, never on sequences.

- `--repeat-penalty` penalises the score of every token seen in the window.
  Binary and per token: it cannot tell a harmful repeat from a legitimate one —
  variable names, braces, quotes, JSON keys. 1.0 disables it.
- `--presence-penalty` subtracts a fixed amount from every token that already
  appeared, however often.
- `--frequency-penalty` subtracts in proportion to how often it appeared.

## DRY

DRY penalises repeated *sequences*. If the next token would continue a sequence
that already appeared, the penalty grows exponentially with the length of the
repeat — each token past `--dry-allowed-length` (2 by default) multiplies it —
and repeats shorter than that are free.

- `--dry-multiplier` strength; 0 disables DRY.
- `--dry-base` how fast the penalty grows; 1.75 by default.
- `--dry-allowed-length` repeats up to this length are free.
- `--dry-penalty-last-n` how far back it looks; 64 by default, 0 disables.

`--dry-sequence-breaker` is a trap: passing it **replaces** the default breakers
(newline, `:`, `"`, `*`) instead of adding to them, and `none` removes all of
them. Those defaults are what keep dialogue formatting and JSON keys from being
penalised.

Unlike the repetition penalties, DRY lets isolated repeated tokens through — the
ones code and JSON need — and reacts only when a stretch is being reproduced.
