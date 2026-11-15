# MEMORY.md — nixos-ci

> Live state of the hosts: what is deployed, on which machine and what is next
> there. **Read it when you start working on this repo and update it when you
> finish.** How the configuration works is in `AGENTS.md`; why the decisions were
> made, in `DECISIONS.md`. The state of the workspace repos lives in the root
> `MEMORY.md`.

Last updated: 2026-11-15.

## Working tree

Clean: everything is committed. `main` is ahead of `origin/main`; the oldest
unpushed commit is `1d45f5c FEATURE - Add jq to the model host`, which adds `jq`
to the host's `environment.systemPackages`. A commit reaches
`nixos-llamaswap-rocm` only when it is pushed to `main`, so nothing in that range
is on the host.

## Hosts

| Host | Service | Deployed | Status |
|---|---|---|---|
| `nixos-ci` | builds LXC images and runs the Forgejo runners | repo configuration | automatic deployment of `nixos-llamaswap-rocm` active from `main` |
| `nixos-llamaswap-rocm` | llama-swap + llama.cpp (ROCm) | llama.cpp `v1.0.0` pinned in the tree; `v0.9.0` is the last version confirmed running | serving GGUFs |
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
Bump llamacpp version`. That is a fact about the repository, not about the host:
the last version confirmed running on the ROCm host is `v0.9.0` (build 8642541,
checked 2026-11-14), and the version every number below was measured on. Nothing
in this repository can confirm what the host runs now. Read the rendered
llama-swap config before quoting what serves today. The store path changes with
every version — find it with `ls -lut /nix/store | grep llamacpp` and take the
newest one.

## `llama-bench` battery

Qwen3.5-9B and Spark were measured; the detail lives in the root `MEMORY.md` and
in `llama-bench-runner/MEMORY.md`.

`spec-bench.sh` swept `--spec-draft-n-max` 2/3/4/6/8 on
`Qwen3.5-9B-UD-Q4_K_XL.gguf` with llama.cpp `v0.9.0`: `2` wins, with 18.15 t/s
against 11.36 without MTP at temp 0 (+60 %) and 13.91 against 11.39 at temp 1
(+22 %, neutral prose and 1.63x on code). The deployed `3` was losing 14 % of
prose at temp 1.

`Unsloth-Qwen3.5-9B-UD-Q4_K_XL.nix` serves the winner:
`${modelLib.specArgs.mtp {nMax = 2;}}`, which renders
`--spec-type draft-mtp --spec-draft-n-max 2` for
`Qwen3.5-9B-UD-Q4_K_XL.gguf`. The rendered config of the host was checked on
2026-11-14 and carried the same two flags; it has not been re-checked since.

The scripts' pin (`llamaBenchRunner`) is not bumped by hand: the deploy workflow
runs `nix run .#update-llama-bench-runner` before building and adopts the
published `main` of the runner repository
(`https://gitlab.com/Gekokeitaro/llama-bench-runner.git`). The rev used is left
in the job log, and a deploy can run a pin ahead of the committed one. The
committed pin is `60f52ddeb5e5ca67edcfc0b7d7926a3cd5369f0a`; whether a deploy has
already moved it is not readable from the repository.

## Deployment

- The workflow `.forgejo/workflows/deploy-llamaswap-rocm.yml` runs on the `ci`
  runner (`runs-on: host`) and deploys `nixos-llamaswap-rocm`:
  - push to `main` → `nixos-rebuild switch` against the host;
  - push to `llamaswap-rocm` → `nixos-rebuild test` (activates in the running
    system without making it the boot default, so a reboot reverts it).
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

1. Normalize `hosts/nixos-pi-agent/config/models.json`: `baseUrl` has a double
   slash (`...:20128//v1`), the API key is in clear text, `defaultModel`
   (`gpt-oss-20b-NEO-IQ4_NL`) does not appear in the model list, and every
   `contextWindow` (262144, or 131072 for the 27B) is larger than the
   `--ctx-size` the model serves (65536 or 32768).
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
