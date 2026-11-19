# MEMORY.md — nixos-ci

> Live state of the hosts: what is deployed, on which machine and what is next
> there. **Read it when you start working on this repo and update it when you
> finish.** How the configuration works is in `AGENTS.md`; why the decisions were
> made, in `DECISIONS.md`. The state of the workspace repos lives in the root
> `MEMORY.md`.

Last updated: 2026-11-19.

## Working tree

Clean: everything is committed. HEAD is this documentation commit, one commit
above `origin/main` and unpushed; `origin/main` is `c010038`, committed on
2026-11-19 at 20:27, so the deployed configuration is `c010038` and these docs
are not on the host. A push to `main` is deployed by the Forgejo workflow on
`nixos-ci` (see `AGENTS.md` for the trigger and its consequence); this file
cannot confirm the revision the host runs, because that is what the job log
records. The rendered llama-swap config was read on the host on 2026-11-19 and
matches `c010038`: the ids are the ones HEAD's model files define, the `cmd`
flags of the reference and Spark are the ones the files write, its filters come
from `modelLib.profiles`, and llama-swap had restarted at 19:49:34 UTC, about
twenty minutes after that commit. A commit above `origin/main` is unpushed and
not on the host until someone pushes.

## Hosts

| Host | Service | Deployed | Status |
|---|---|---|---|
| `nixos-ci` | builds LXC images and runs the Forgejo runners | repo configuration | runs the deploy workflow; its last observed run switched `nixos-llamaswap-rocm` on 2026-11-19 |
| `nixos-llamaswap-rocm` | llama-swap + llama.cpp (ROCm) | `c010038`, by the rendered config read on 2026-11-19; the tree pins llama.cpp `v1.0.0` | serving GGUFs |
| `nixos-pi-agent` | `pi` sessions against OmniRoute | configuration on `main` | manual deployment; `models.json` needs normalising (see Pending) |

`nixos-forgejo` hosts Forgejo with Actions active and registration closed.
`nixos-ci` runs two runners: `ci` (`host:host`, deployment) and
`nixos-runner` (`docker`, container jobs). The rest of the hosts
(`nixos-n8n`, `nixos-n8n-runner`, `nixos-omniroute`, `nixos-postgresql`,
`nixos-hindsight`, `nixos-calibre-wa`) run the repo configuration with no
state of their own to record here.

## llama.cpp

The tree pins `v1.0.0`: `llamacppVersion` in
`hosts/llamaswap-lxc/packages/llama-cpp/default.nix`, set by `3c8de35 CHORE -
Bump llamacpp version`. The host runs it: the delayed wrapper read there on
2026-11-19 execs a `llama-cpp-v1.0.0` store path. `v0.9.0` (build 8642541, the
previous confirmed state) is no longer what runs there; it stays below as the
version the 2026-11-12 battery and the `v0.9.0` spec sweep were measured on. The
job log holds the llama.cpp version and the `llamaBenchRunner` revision each
build resolved, and nothing in this repository can confirm them.
Read the rendered llama-swap config before quoting what serves today. The store
path changes with every version — find it with `ls -lut /nix/store | grep
llamacpp` and take the newest one.

## `llama-bench` battery

Qwen3.5-9B and Spark were measured; the detail lives in the root `MEMORY.md` and
in `llama-bench-runner/MEMORY.md`.

`spec-bench.sh` swept `--spec-draft-n-max` 2/3/4/6/8 on
`Qwen3.5-9B-UD-Q4_K_XL.gguf` with llama.cpp `v0.9.0`: `2` won that round, with
18.15 t/s against 11.36 without MTP at temp 0 (+60 %) and 13.91 against 11.39 at
temp 1 (+22 %, neutral prose and 1.63x on code). The `v1.0.0` spec bench of the
same GGUF replaced that round: `draft-mtp` with `n-max 1` is 1.311x global, and
adding `ngram-mod` at 24:32:64 is 1.359x, which is the preset the file serves.

`Unsloth-Qwen3.5-9B-UD-Q4_K_XL.nix` writes those flags itself, because the combo
spans two spec types and the library fragment covers one. `e9d4069` landed the
preset and `f9a1c32` corrected its header, and the root `MEMORY.md` records the
deploy on 2026-11-18. The rendered config read on the host on 2026-11-19 agrees:
`--spec-type draft-mtp,ngram-mod --spec-draft-n-max 1` with the 24:32:64 triple
under `--ctx-size 163840`, and `/v1/models` lists the bare id plus `:planner`,
`:implementer`, `:reviewer`, `:supervisor`, `:integrator` and `:instruct`. The
`v0.9.0` flags that the host carried when it was read on 2026-11-14
(`--spec-type draft-mtp --spec-draft-n-max 2`) are gone.

The scripts' pin (`llamaBenchRunner`) is not bumped by hand: the deploy workflow
runs `nix run .#update-llama-bench-runner` before building and adopts the
published `main` of the runner repository
(`https://gitlab.com/Gekokeitaro/llama-bench-runner.git`). The bump lands in the
workflow's own checkout and is never committed, so the deployed scripts can be
ahead of the committed pin `139c6f1f7e9edf2132f912f87ed6a3111d3aac44`. The
revision each deploy resolved is in its job log and is not readable from the
repository.

## Deployment

- The workflow `.forgejo/workflows/deploy-llamaswap-rocm.yml` runs on the `ci`
  runner (`runs-on: host`) and deploys `nixos-llamaswap-rocm`:
  - push to `main` → `nixos-rebuild switch` against the host;
  - push to `llamaswap-rocm` → `nixos-rebuild test` (activates in the running
    system without making it the boot default, so a reboot reverts it);
  - `workflow_dispatch` runs the same job on demand.
- The pushes of `main` on 2026-11-15 (`697c811` at 18:17, `035d7d1` at 18:29)
  ran it and switched the host. The latest observed run switched it again on
  2026-11-19, after `c010038`: llama-swap's `start_time` is 19:49:34 UTC and the
  rendered config matches that commit.
- The deploy key is the sops secret `deploy-key` of `hosts/nixos-ci`;
  systemd exposes it as a credential to the `forgejo-runner-ci` service.
- `nixos-ci` cannot `git pull` from GitHub (its key is not authorized):
  manual pulls run from the dev machine or the user does them.
  The Forgejo runner does its own checkout, so the deployment does not depend
  on that pull.
- The rest of the hosts are applied by hand: the workflow deploys only
  `nixos-llamaswap-rocm` from `main`, so a change in another host does not
  arrive on its own.

## Pending

1. Normalize `hosts/nixos-pi-agent/config/`. In `models.json`, `baseUrl` has a
   double slash (`...:20128//v1`), the API key is in clear text, and every
   `contextWindow` (262144, or 131072 for the 27B) is larger than the
   `--ctx-size` the model file serves (163840 for the reference, 32768 for
   Gemma 4 12B and the 27B). `OmniCoder-9B Q5_K_M DFlash` has no live entry at
   all: its file is in `models/archived/`. In `settings.json`, `defaultModel` is
   `gpt-oss-20b-NEO-IQ4_NL`, which appears in no model list.
2. Point the n8n runner at the task broker. `N8N_RUNNERS_TASK_BROKER_URI` in
   `hosts/nixos-n8n-runner/configuration.nix` uses `5678`, which is n8n's own
   HTTP port; the task broker listens on `5679`, and `hosts/nixos-n8n` publishes
   both.
3. Decide what to do with `hosts/pihole-lxc/`: it exists but has no output in
   `flake.nix` and no documentation of its own.
4. Apply `nixos-ci` by hand. The tree already puts `nix` in the `path` of
   `forgejo-runner-ci` (`hosts/nixos-ci/modules/forgejo-runner.nix`); until that
   reaches the host, the workflow prepends `/run/current-system/sw/bin`, and
   that prepend can be removed after the host's `nixos-rebuild switch`.
5. Verify the fragment-library refactor post hoc: it reached the host with the
   2026-11-15 deploy, so compare the served model ids and the rendered
   llama-swap config on the host against `e52c157`, the last commit before the
   refactor. Same ids and same `cmd` text means the refactor rendered identical.
   Later deploys moved the host past that point, so today's rendering also
   carries `e9d4069` and everything after it; the comparison now needs
   `e52c157` rendered rather than read from the host.
