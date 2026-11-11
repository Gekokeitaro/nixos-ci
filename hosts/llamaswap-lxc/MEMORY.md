# MEMORY.md — llamaswap-lxc

State of this host and what is still open. Mechanics live in `AGENTS.md`; what is
deployed on the host, in [`nixos-ci/MEMORY.md`](../../MEMORY.md).

Last updated: 2026-11-11.

## Sampling

- 15 of the 17 model files serve the default sampler chain. Only Spark X2.6 4B and
  Gemma 4 12B spell their own: `top_k;top_p;min_p;temperature;dry;typ_p;xtc`.
- **Open: `--repeat-penalty 1.1` is inert in both.** Their chain has no `penalties`
  stage, so the flag does nothing. Left as it is on purpose: adding the stage would
  change what two already-evaluated models generate. Decide with quality
  measurements, not by eye.
- **Open: the `:dry-budget-4000*` variants set `reasoning_budget = 4096`.** The
  suffix says 4000. Rename one or the other deliberately, not by accident.
- **Open: in both custom chains temperature runs ahead of DRY**, unlike the default
  chain. Unclear whether that is intended; the order changes the result.
- **Open: how to disable XTC.** `llama-server --help` prints `1.0 = disabled` for
  `--xtc-threshold`; the server README says anything above `0.5` disables it. XTC is
  off while `--xtc-probability` stays at 0, so nothing depends on it today.

Confirmed on the running server, 2026-11-11: `GET /props` of a loaded model
reports the chain given by `--samplers`, not the request default that the server
README lists for `/completion` (which omits `penalties` and `top_n_sigma`). So the
flag in `commonArgs` is what applies.

Per-model knob values are in each model's `.nix`, where they are applied.
