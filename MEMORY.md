# MEMORY.md — nixos-ci

> Live state of the hosts: what is deployed, on which machine and what is next
> there. **Read it when you start working on this repo and update it when you
> finish.** How the configuration works is in `AGENTS.md`; why the decisions were
> made, in `DECISIONS.md`. The state of the workspace repos lives in the root
> `MEMORY.md`.

Last updated: 2026-11-15.

## Working tree

- Three local commits, unpushed, carry the model-file fragment library:
  `FEATURE` adds `models/lib/default.nix` and the `modelLib` injection in
  `models/default.nix`; `REFACTOR` migrates the 16 model files with an identical
  rendered `cmd` and identical `filters`; `DOCS` writes
  `skills/model-files/references/module-shape.md` and updates the host docs,
  `DECISIONS.md` and this file.
- The rest of the change set below is uncommitted and unpushed; the ROCm host
  still runs the last deployed revision.
- The repository is translated to English: the comments, messages and CI step
  names of 22 `.nix`/`.yml` files, two systemd `description`s, `MEMORY.md` and the
  comment-language rule in `AGENTS.md`. The `DECISIONS.md` entry of 2026-11-15
  records that.
- Two skills own procedures that used to sit in the host `AGENTS.md`:
  `model-files` (creating, renaming and archiving an entry under `models/`) and
  `sampling` (the chain, the samplers, the penalties, DRY, the reasoning budget,
  the `--spec-*` flags), each with `references/` and `evals/<id>.json`.
  `hosts/llamaswap-lxc/AGENTS.md` keeps the rules and points at them.
- Still uncommitted: `AGENTS.md`, `README.md`, the host `MEMORY.md`, the
  translated archived models, the deploy workflow, `flake.nix`, `common/`, the
  remaining host configurations and `utils/`; `skills/sampling/` and `evals/` are
  untracked.

## Hosts

| Host | Service | Deployed | Status |
|---|---|---|---|
| `nixos-ci` | builds LXC images and runs the Forgejo runners | repo configuration | automatic deployment of `nixos-llamaswap-rocm` active from `main` |
| `llamaswap-lxc` | llama-swap + llama.cpp (ROCm) | llama.cpp `v1.0.0` pinned in the tree; `v0.9.0` was the last verified deploy | serving GGUFs |
| `nixos-pi-agent` | `pi` sessions against OmniRoute | configuration on `main` | manual deployment; `models.json` pending |

`nixos-forgejo` hosts Forgejo with Actions active and registration closed.
`nixos-ci` runs two runners: `ci` (`host:host`, deployment) and
`nixos-runner` (`docker`, container jobs). The rest of the hosts
(`nixos-n8n`, `nixos-n8n-runner`, `nixos-omniroute`, `nixos-postgresql`,
`nixos-hindsight`, `nixos-calibre-wa`) run the repo configuration with no
state of their own to record here.

## llama.cpp

The tree pins `v1.0.0` (`3c8de35`, "Bump llamacpp version") and the ROCm host
deploys from `main`; `v0.9.0` (build 8642541) is the last build confirmed running
there, and the version every number below was measured on. Read the rendered
llama-swap config before quoting what serves today. The store path changes with
every version — find it with `ls -lut /nix/store | grep llamacpp` and take the
newest one.

## `llama-bench` battery

Qwen3.5-9B and Spark measured; the detail lives in the root `MEMORY.md` and in
`llama-bench-runner/MEMORY.md`.

`spec-bench.sh` swept `--spec-draft-n-max` 2/3/4/6/8 on
`Qwen3.5-9B-UD-Q4_K_XL.gguf` with llama.cpp `v0.9.0`: `2` wins, with 18.15 t/s
against 11.36 without MTP at temp 0 (+60 %) and 13.91 against 11.39 at temp 1
(+22 %, neutral prose and 1.63x on code). The deployed `3` was losing 14 % of
prose at temp 1.

The model serves `--spec-draft-n-max 2` since the 2026-11-14 deployment:
checked in the rendered llama-swap config, which carries
`--spec-type draft-mtp --spec-draft-n-max 2` for `Qwen3.5-9B-UD-Q4_K_XL.gguf`.

The scripts' pin (`llamaBenchRunner`) is no longer bumped by hand: the deploy
workflow runs `nix run .#update-llama-bench-runner` before building and adopts
the published `main` of the runner repo. The rev used is left in the job log,
and what is deployed can be ahead of the committed pin. Until the first push
with this automation, the pin stays at `60f52dd`.

## Deployment

- The workflow `.forgejo/workflows/deploy-llamaswap-rocm.yml` runs on the `ci`
  runner (`runs-on: host`) and deploys `nixos-llamaswap-rocm`:
  - push to `main` → `nixos-rebuild switch` against the host;
  - push to `llamaswap-rocm` → `nixos-rebuild test` (builds without activating).
- The deploy key is the sops secret `deploy-key` of `hosts/nixos-ci`;
  systemd exposes it as a credential to the `forgejo-runner-ci` service.
- `nixos-ci` cannot `git pull` from GitHub (its key is not authorized):
  manual pulls run from the dev host or the user does them.
  The Forgejo runner does its own checkout, so the deployment does not depend
  on that pull.
- The rest of the hosts are applied by hand: the workflow only triggers from
  `main` and `llamaswap-rocm`, so a change in another host does not arrive on
  its own.

## Pending

1. Normalize `hosts/nixos-pi-agent/config/models.json`: `baseUrl` has a double
   slash (`...:20128//v1`), the API key is in clear text and `defaultModel` does
   not appear in the model list.
2. Check the n8n broker: the runner points at port `5678`, but `5679` is
   published too.
3. Decide what to do with `hosts/pihole-lxc/`: it exists but has no output in
   `flake.nix` and no documentation of its own.
4. Apply `nixos-ci` by hand: the `forgejo-runner-ci` service gains `nix` in its
   `path` so the workflow steps can use `nix run`. The workflow already manages
   by prepending `/run/current-system/sw/bin`, but that is a patch until this
   host's `nixos-rebuild switch`.
