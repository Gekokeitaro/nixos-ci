# Samplers

Defaults measured at llama.cpp 0.9.0.

| Sampler | Flag | Effect | Cost |
|---|---|---|---|
| temperature | `--temp` | sharpens the scores below 1, flattens them above 1 | the global precision/variety knob |
| top-k | `--top-k` | keeps the K best candidates; 0 disables | fixed, ignores how sure the model is |
| top-p | `--top-p` | keeps the smallest set that adds up to probability p; 1.0 disables | adapts to confidence |
| min-p | `--min-p` | drops anything below p × the best candidate; 0 disables | adapts, and holds up better than top-p at high temperature |
| XTC | `--xtc-probability`, `--xtc-threshold` | with probability p removes the most likely candidates above the threshold (0.10 by default); off until p > 0 | creative writing |

`--grammar` and `--json-schema` are not samplers: they forbid the tokens that
would break the format. `--logit-bias` adds a fixed amount to named tokens.
