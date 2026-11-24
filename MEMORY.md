# MEMORY.md — nixos-ci

> Live state of the hosts: what is deployed, where it runs, and where the
> evidence sits. **Read it at the start of a session and update it at the end.**
> Rules in `AGENTS.md`, decisions in `DECISIONS.md`, addresses and ports in
> `INFRA.md`, open work in `TASKS.md`, workspace state in the root `MEMORY.md`.

Last updated: 2026-11-24.

## Working tree

Clean, and `HEAD` equals `origin/main` as last fetched: the repo is pushed. The deploy of
**`8644dc7` on 2026-11-24 07:59:26 UTC** is the last one read on the host: the system generation
changed to `f7qacldz…`, and the rendered config at that moment carries the six roles on the Gemma
12B/E4B and on both Qwen3.8 27B entries, the 12B MTP entry with the measured
`ngram-mod,draft-mtp` preset, and `--lora /models/Qwen3.8-27B-pi-lora-F16.gguf` on the two 27Bs.
A push to `main` deploys: **the job log records whether the switch ran**, and it, not this file,
holds the revision. An hourly mirror sync also arrives as a push event, so a restart of
`llama-swap` alone is not proof of a deploy — the **generation** is
(`readlink -f /run/current-system`). Earlier switches read here: `f2ed2c4` on 2026-11-23 21:16,
`9944b2c` at 19:00, `6e4f369` at 11:59.

## Hosts

| Host | Service | Deployed | Status |
|---|---|---|---|
| `nixos-ci` | builds LXC images and runs the Forgejo runners | repo configuration | runs the deploy workflow; its last observed run switched `nixos-llamaswap-rocm` on 2026-11-24 |
| `nixos-llamaswap-rocm` | llama-swap + llama.cpp (ROCm) | `8644dc7`, generation `f7qacldz…`, switch at 2026-11-24 07:59:26 UTC; the tree pins llama.cpp `v1.0.0` | serving GGUFs |
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
`196608` with the default chain and no spec. `Unsloth Qwen3.6 35B A3B REAP 48 v2`
serves `--ctx-size 163840`, `-t 1 -b 2048 -ub 512`, `ngram-mod` 24:32:48 and the
six roles, with **no MTP: the GGUF carries none**; its bare id was pinned to the
vendor's `thinking` preset on 2026-11-22 (`6e4f369`), which retires the no-filter
CORE the 54/96 was measured on. **Gemma 4 12B** serves the card's preset
(`--temp 1 --top-p 0.95 --top-k 64`) on the bare id and, on the `MTP` entry, the measured
two-family combination (`ngram-mod,draft-mtp`, `--spec-draft-n-max 8 --spec-draft-p-min 0.4`,
ngram 12:32:64, 3.604× global at temp 1); both entries carry the six roles. **Gemma 4 E4B**
serves `ngram-mod,draft-mtp` at `65536` with the card's sampling and, since `8644dc7`, the six
roles. **The two Qwen3.8 27B entries** (`David AU TBrill 50X`, `Ukisai Swift 1.5`) serve at
`32768` with the six roles and `--lora /models/Qwen3.8-27B-pi-lora-F16.gguf` at scale 1.0; neither
has a measured window, session pass or LoRA A/B yet. The numbers behind the presets are in
`../llama-bench-runner/measurements/` (`qwen3.5-9b-ud-q4_k_xl/`, `spark-x2.6-4b-q8_0.md`,
`qwen3.6-35b-a3b-reap-48-v2.md`, `gemma-4-12b-it-qat-ud-q4-k-xl.md`, and the 27B file). Host
tuning and open items: `hosts/llamaswap-lxc/MEMORY.md`.
