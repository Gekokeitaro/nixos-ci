# ADR 0002 — Role profiles share one entry and one sampler geometry

**Date**: 2026-11-18

**Status**: Accepted.

## Context

The reference model serves one GGUF behind one `cmd`, and that `cmd` carries the
speculative preset (`--spec-type draft-mtp,ngram-mod`). `--spec-*` are startup
flags, so every client id of the entry drafts with the same stack. Session 7 of
the workspace plan asks for role variants — planner, implementer, reviewer,
supervisor, integrator — while session 8 measures one baseline per role.

A role variant that changed `top_k`, `top_p` or `min_p` would sample the drafted
and the accepted tokens under a different geometry, so its measurement would no
longer be comparable to the control of 2026-11-18 or to the other roles.

## Decision

- The five roles live in `modelLib.profiles.roles`, over a shared `roleBase` that
  holds every value the roles must keep equal: `top_p 0.95`, `top_k 20`,
  `min_p 0.0`, `presence_penalty 0.0`, `repeat_penalty 1.0` and
  `dry_multiplier 0.0`.
- Each role moves exactly one axis: temperature or reasoning budget. The axis and
  its reason are commented on each entry of `profiles.roles`.
- `presence_penalty` and DRY are per-GGUF corrections, not role axes: the reference
  model's copy round of 2026-11-16 took both to 0, and the roles inherit that.
- The reference model file serves the five roles through `mkFilters` next to the
  bare id, which stays exactly as measured. One entry, six client ids, no second
  `cmd` and no reload between ids.
- The entry drops `:coding` and `:instruct`: the role set covers both, and the
  catalog is read from the ids the entry serves.

## Rationale

One entry is one load and one spec stack, so six ids cost the memory of one model
and switching between them is a request, not a swap. Freezing the truncation
geometry is what makes a role comparable: the only difference between a role and
the control is the axis that role was given, and a regression can be attributed to
it. Keeping the bare id byte-identical keeps the CORE of 2026-11-18 valid as the
control it already is.
