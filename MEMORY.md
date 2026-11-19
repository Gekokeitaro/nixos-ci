# MEMORY.md — nixos-ci

> Live state of the hosts: what is deployed, where it runs, and where the
> evidence sits. **Read it at the start of a session and update it at the end.**
> Rules in `AGENTS.md`, decisions in `DECISIONS.md`, addresses and ports in
> `INFRA.md`, open work in `TASKS.md`, workspace state in the root `MEMORY.md`.

Last updated: 2026-11-19.

## Working tree

Clean: everything is committed. The branch is ahead of `origin/main` and
unpushed; read its exact HEAD with `git log -1`. `origin/main` is `c010038`,
committed on 2026-11-19 at 20:27, so the deployed configuration is `c010038` and
these docs are not on the host until someone pushes them (a push to `main`
deploys: see `AGENTS.md`). The pushes of 2026-11-15 (`697c811` at 18:17, `035d7d1`
at 18:29) ran the workflow and switched the host. The rendered config read on the
host on 2026-11-19 matches `c010038` — the ids HEAD's model files define, the
`cmd` flags of the reference and Spark, the `modelLib.profiles` filters — and
llama-swap had restarted at 19:49:34 UTC, twenty minutes after that commit. The
job log, not this file, records the revision the host runs.

## Hosts

| Host | Service | Deployed | Status |
|---|---|---|---|
| `nixos-ci` | builds LXC images and runs the Forgejo runners | repo configuration | runs the deploy workflow; its last observed run switched `nixos-llamaswap-rocm` on 2026-11-19 |
| `nixos-llamaswap-rocm` | llama-swap + llama.cpp (ROCm) | `c010038`, by the rendered config read on 2026-11-19; the tree pins llama.cpp `v1.0.0` | serving GGUFs |
| `nixos-pi-agent` | `pi` sessions against OmniRoute | configuration on `main` | manual deployment; `models.json` needs normalising (see `TASKS.md`) |

`nixos-forgejo` hosts Forgejo with Actions active and registration closed;
`nixos-ci` runs the `ci` (`host:host`) and `nixos-runner` (`docker`) runners. The
rest (`nixos-n8n`, `nixos-n8n-runner`, `nixos-omniroute`, `nixos-postgresql`,
`nixos-hindsight`, `nixos-calibre-wa`) records no state here.

## llama.cpp

The tree pins `v1.0.0`: `llamacppVersion` in
`hosts/llamaswap-lxc/packages/llama-cpp/default.nix`, set by `3c8de35 CHORE -
Bump llamacpp version`. The host runs it: the delayed wrapper read there on
2026-11-19 execs a `llama-cpp-v1.0.0` store path. `v0.9.0` (build 8642541, the
previous confirmed state) no longer runs there: the 2026-11-12 battery and the
`v0.9.0` spec sweep were measured on it, and their numbers are in
`../llama-bench-runner/`. The store path changes with every version: take the
newest of `ls -lut /nix/store | grep llamacpp` before quoting what serves today.

The committed benchmark-scripts pin is `llamaBenchRunner`, rev
`139c6f1f7e9edf2132f912f87ed6a3111d3aac44`. The deploy workflow bumps it in its
own checkout, so the deployed scripts can be ahead of that pin and the job log is
the record of what each deploy resolved (see `AGENTS.md`).

## Verified

- The fragment-library refactor preserves behaviour at the llama-swap argument
  level. `e52c157` (last commit before it) and `1089dc0 REFACTOR - Migrate the
  model files to the fragment library` (`7ca3eed` added the library) both
  render 17 model ids, with identical `filters`. The `cmd` text differs on 16
  models only in flag order, blank lines and Nix float formatting
  (`--spec-draft-p-min 0.6` → `0.600000`), and a shell-token comparison found
  identical argv on all 17. Measured 2026-11-19 by `nix eval` of
  `config.services.llama-swap.settings.models` on a path flake of each commit,
  then a shell-token comparison of every `cmd`.

## Served configuration

`nixos-llamaswap-rocm` serves `Qwen3.5-9B-UD-Q4_K_XL` under one
`draft-mtp,ngram-mod` preset (`--spec-draft-n-max 1`, 24:32:64) at
`--ctx-size 163840`, as the bare id plus `:planner`, `:implementer`, `:reviewer`,
`:supervisor`, `:integrator` and `:instruct`; the file writes those flags itself,
the combo spanning two spec types. `e9d4069` landed the preset, `f9a1c32`
corrected its header, and it was deployed on 2026-11-18. Spark X2.6 4B serves at
`196608` with the default chain and no spec. The numbers behind both presets are
in `../llama-bench-runner/measurements/qwen3.5-9b-ud-q4_k_xl/` and
`spark-x2.6-4b-q8_0.md`. Host tuning and open items:
`hosts/llamaswap-lxc/MEMORY.md`.
