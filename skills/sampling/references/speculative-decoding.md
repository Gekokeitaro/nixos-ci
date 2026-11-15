# Speculative decoding flags

Measuring a preset — probe, grid, refine, gates — belongs to the `spec-decoding`
and `tuning-loop` skills in `llama-bench-runner`. This file is what the flags mean
when you read or write them in a model file.

Flag defaults and the ngram cost measured at llama.cpp 0.9.0; the cost was
measured on Qwen3.5-9B.

A draft model proposes the next few tokens and the target checks them, so the
speedup depends on how many proposals survive. Here the draft is an MTP head
(`--spec-type draft-mtp` plus `-md`), and `--spec-draft-n-max` (3 by default) is
how many tokens it proposes per step. `--spec-draft-n-min` (0 by default) is the
minimum number of draft tokens used; `--spec-draft-p-min` and
`--spec-draft-p-split` set how many proposals survive.

`--spec-draft-sampling` decides how the draft picks: `greedy` (default) takes its
best token, `probabilistic` samples the draft and has the target verify it by
rejection sampling. Under `greedy` a proposal only survives if the target would
have drawn that same token, so the more random the target's sampling — high
temperature, XTC — the fewer proposals survive and the smaller the speedup.

`ngram*` spec types were banned until their cost was investigated. `ngram-mod`
costs +59 MiB loaded and +123 MiB once it generates, constant from 4k to 49k of
context, and scales at ~0.93 MiB per draft token of `--spec-ngram-mod-n-max`. That
is not a memory problem, so the ban is lifted; acceptance and speed are a separate
question for a spec-decoding benchmark.

`ngram-mod` and `draft-mtp` are not alternatives. ngram only drafts where the
context repeats something already seen, so on novel text it has nothing to offer
and MTP drafts instead: an agentic session uses both, and a combo pays both
stacks. A single prompt full of repeated code shows only ngram drafting, which is
why the combo looks redundant there and is not.

`--spec-*` are server flags: they go in `cmd`, never in `filters.setParamsByID`.
