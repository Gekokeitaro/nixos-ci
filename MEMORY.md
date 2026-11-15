# MEMORY.md — nixos-ci

> Live state of the hosts: what is deployed, on which machine and what is next
> there. **Read it when you start working on this repo and update it when you
> finish.** How the configuration works is in `AGENTS.md`; why the decisions were
> made, in `DECISIONS.md`. The state of the workspace repos lives in the root
> `MEMORY.md`.

Last updated: 2026-11-15.

## Working tree

Clean: everything is committed. `origin/main` is `697c811`, pushed on
2026-11-15 at 18:17, and that push ran the deploy workflow, so
`nixos-llamaswap-rocm` runs that revision. A commit above it is unpushed and not
on the host until someone pushes; the job log, not this file, records what the
build resolved.

## Hosts

| Host | Service | Deployed | Status |
|---|---|---|---|
| `nixos-ci` | builds LXC images and runs the Forgejo runners | repo configuration | automatic deployment of `nixos-llamaswap-rocm` ran from `main` on 2026-11-15 |
| `nixos-llamaswap-rocm` | llama-swap + llama.cpp (ROCm) | `697c811`, deployed 2026-11-15; the tree pins llama.cpp `v1.0.0` | serving GGUFs |
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
Bump llamacpp version`. That pin reached the host with the deploy of `697c811`
on 2026-11-15, so `v0.9.0` (build 8642541, the previous confirmed state) is no
longer what runs there; it stays below as the version the measurements were
taken on. The job log holds the llama.cpp version and the `llamaBenchRunner`
revision the build resolved, and nothing in this repository can confirm them.
Read the rendered llama-swap config before quoting what serves today. The store
path changes with every version — find it with `ls -lut /nix/store | grep
llamacpp` and take the newest one.

## `llama-bench` battery

Qwen3.5-9B and Spark were measured; the detail lives in the root `MEMORY.md` and
in `llama-bench-runner/MEMORY.md`.

`spec-bench.sh` swept `--spec-draft-n-max` 2/3/4/6/8 on
`Qwen3.5-9B-UD-Q4_K_XL.gguf` with llama.cpp `v0.9.0`: `2` wins, with 18.15 t/s
against 11.36 without MTP at temp 0 (+60 %) and 13.91 against 11.39 at temp 1
(+22 %, neutral prose and 1.63x on code). The `3` that was deployed then lost
14 % of prose at temp 1.

`Unsloth-Qwen3.5-9B-UD-Q4_K_XL.nix` serves the winner:
`${modelLib.specArgs.mtp {nMax = 2;}}`, which renders
`--spec-type draft-mtp --spec-draft-n-max 2` for
`Qwen3.5-9B-UD-Q4_K_XL.gguf`. The host's rendered config carried those two flags
when it was read on 2026-11-14, before the fragment-library refactor; the
rendering of `697c811` has not been read yet (see Pending).

The scripts' pin (`llamaBenchRunner`) is not bumped by hand: the deploy workflow
runs `nix run .#update-llama-bench-runner` before building and adopts the
published `main` of the runner repository
(`https://gitlab.com/Gekokeitaro/llama-bench-runner.git`). The bump lands in the
workflow's own checkout and is never committed, so the deployed scripts can be
ahead of the committed pin `60f52ddeb5e5ca67edcfc0b7d7926a3cd5369f0a`. The
revision the 2026-11-15 deploy used is in its job log and is not readable from
the repository.

## Deployment

- The workflow `.forgejo/workflows/deploy-llamaswap-rocm.yml` runs on the `ci`
  runner (`runs-on: host`) and deploys `nixos-llamaswap-rocm`:
  - push to `main` → `nixos-rebuild switch` against the host;
  - push to `llamaswap-rocm` → `nixos-rebuild test` (activates in the running
    system without making it the boot default, so a reboot reverts it).
- The push of `main` at `697c811` ran it on 2026-11-15 and switched the host.
- The deploy key is the sops secret `deploy-key` of `hosts/nixos-ci`;
  systemd exposes it as a credential to the `forgejo-runner-ci` service.
- `nixos-ci` cannot `git pull` from GitHub (its key is not authorized):
  manual pulls run from the dev machine or the user does them.
  The Forgejo runner does its own checkout, so the deployment does not depend
  on that pull.
- The rest of the hosts are applied by hand: the workflow only triggers from
  `main` and `llamaswap-rocm`, so a change in another host does not arrive on
  its own.

## Pending

1. Normalize `hosts/nixos-pi-agent/config/`. In `models.json`, `baseUrl` has a
   double slash (`...:20128//v1`), the API key is in clear text, and every
   `contextWindow` (262144, or 131072 for the 27B) is larger than the
   `--ctx-size` the model file serves (65536 or 32768). In `settings.json`,
   `defaultModel` is `gpt-oss-20b-NEO-IQ4_NL`, which appears in no model list.
2. Check the n8n broker: the runner points at port `5678`, but `5679` is
   published too.
3. Decide what to do with `hosts/pihole-lxc/`: it exists but has no output in
   `flake.nix` and no documentation of its own.
4. Apply `nixos-ci` by hand. The tree already puts `nix` in the `path` of
   `forgejo-runner-ci` (`hosts/nixos-ci/modules/forgejo-runner.nix`); until that
   reaches the host, the workflow prepends `/run/current-system/sw/bin`, and
   that prepend can be removed after the host's `nixos-rebuild switch`.
5. Resolve OmniRoute's address: `INFRA.md` records `192.168.18.28`, while
   `hosts/nixos-hindsight/configuration.nix` and the `nixos-pi-agent` config and
   docs still point at `192.168.18.32:20128`. One of the two is stale; Proxmox
   is the only place that settles it.
6. Verify the fragment-library refactor post hoc: it reached the host with the
   2026-11-15 deploy, so compare the served model ids and the rendered
   llama-swap config on the host against `e52c157`, the last commit before the
   refactor. Same ids and same `cmd` text means the refactor rendered identical.
