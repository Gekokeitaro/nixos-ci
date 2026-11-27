# ADR 0003 — llama.cpp pins live in one file, and its build metadata is derived

**Date**: 2026-11-27

**Status**: Accepted.

## Context

`hosts/llamaswap-lxc/packages/llama-cpp/default.nix` overrode `pkgs.llama-cpp`
with four values typed by hand: `llamacppVersion`, `llamacppHash`,
`llamacppNpmHash`, and — inherited untouched from nixpkgs — `buildNumber` and
`buildCommit`. nixpkgs pins the last two for llama.cpp 0.8.0 (`11960` / the
commit of its "bump version to 0.8.0" change, `8642541`), and passes them as
`-DLLAMA_BUILD_NUMBER` and `-DLLAMA_BUILD_COMMIT`. The override rewrote `src`
and `version` only, then prepended `-DLLAMA_BUILD_COMMIT=${version}` — a tag in
a slot that takes a commit hash. `/props` therefore answered `b11960-v1.0.0`:
not a version bump, but 0.8.0's metadata wearing v1.0.0's label.

The same shape failed the other way round during the check that produced this
ADR: v1.0.0's tag peels to `b1b770d90d94cad9e9ea5b993bdbc383a522fb28` and its
release asset `nightly-tag.txt` says `b12359`. Neither equals nixpkgs' pair, so
a pin copied from `/props` would have encoded the stale values rather than the
truth.

Upstream also moved the web UI from `tools/ui` to `ui/apps/chat` in v1.1.0
while nixpkgs still sets `npmRoot = "tools/ui"`, so a major bump breaks in the
`npm-deps` fixed-output derivation rather than at a place that says why.

The repository pinned v1.0.0 when this work began, and another commit bumped it
to v1.1.0 while it was in progress (`658c3b9 CHORE - Bump llamacpp version`).
`versions.nix` therefore carries v1.1.0 — commit
`171527522610996f5f0acf12334e185156ca8f44`, build `b12774` — so replacing the
hand-typed values neither downgrades the host nor bumps it.

## Decision

- `hosts/llamaswap-lxc/packages/llama-cpp/versions.nix` is the only file with
  mutable pins: `version`, `rev`, `hash`, `npmHash`, `buildNumber`. `rev` is the
  40-hex commit, never the tag.
- `default.nix` imports it, derives `buildCommit` as the first 7 characters of
  `rev` and `buildNumber` as the pin without its `b`, and passes both through
  `prependToVar` from those bindings. No literal build metadata remains.
- `npmRoot` is pinned explicitly to `ui/apps/chat` — where v1.1.0 keeps the web
  UI, which it moved from `tools/ui` — next to a comment naming that move,
  instead of being inherited from nixpkgs' `tools/ui`.
- Evaluation fails before any compile when: `version` is not `vX.Y.Z`, `rev` is
  not 40 lowercase hex, `rev` starts with `v`, `buildNumber` is not `b<digits>`,
  the build metadata nixpkgs supplies is no longer exactly one
  `-DLLAMA_BUILD_NUMBER` plus one `-DLLAMA_BUILD_COMMIT` (the pair the override
  filters out), or `src` has no `ui/apps/chat` directory.
- `nix run .#update-llama-cpp` is the only writer of `versions.nix`. It resolves
  the tag's commit through `nix-prefetch-github` and confirms it against the
  GitHub tag object, reads the build number from the release's
  `nightly-tag.txt`, checks any build/commit a tag announces in its own name,
  writes the file whole to a temporary copy in the same directory and `mv`s it,
  restores the previous file on any failure, and re-evaluates the written file
  before reporting success.
- Coherence between `version` and `rev` is not asserted in Nix: without network
  the evaluator cannot know which commit a tag names, and a hardcoded table
  would reintroduce the lie. It is enforced where there is network — the updater
  — and observed after each deployment by comparing `/props`'s `build_info` with
  the pin.

## Rationale

One file, one writer, and every derived value computed from it means a pin can
no longer drift from the metadata that reports it. The difference between nixpkgs'
0.8.0 pair and v1.0.0's real pair is exactly the class of error the asserts
target: a value that is plausible, committed, and wrong. Failing at evaluation
costs a minute; failing after a deploy leaves a server that reports a build it
never ran, which is what this ADR removes.
