# TASKS.md — nixos-ci

Open work of this repository. A task is deleted when it lands; what it taught
moves to the file that owns it.

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
5. **The 35B serves 163840 and has its baseline.** `--ctx-size 163840` (its ceiling is 196608
   at load; 229376 misses by 34 MiB) with the battery in its header, deployed 2026-11-20. Its
   first CORE `k=3` is done: **45/96**, `cross` 12/12 and `planner` 2/12
   (`ai-tests/measurements/qwen3.6-35b-a3b-reap-48-v2.md`). Threads are settled: `-t 1` wins on
   both prompt sizes (`pp512` 348, `pp4096` 302) against `-t 2/4/8`. **Owed: the six roles.**
   `Unsloth-Qwen3.6-35B-A3B-REAP-48-v2.nix` still serves the legacy filters
   (`default = profiles.agent`, `thinking`, `coding`, `instruct`), so adopting
   `profiles.roles` changes the bare id's sampling as well as adding the role budgets — and
   that invalidates the 45/96 above, which is why it wants its own CORE afterwards. `ngram` is
   the only speculative path left untested on it (no MTP heads).
6. **`reasoning_effort` is a lever, and it travels from the client (decided 2026-11-20).** It
   exists only where the GGUF template implements it: the 27B base quants and two served 27B
   entries (`Ukisai Swift 1.5`, `Ternary Bonsai 2 27B`) declare `{xhigh, medium, low}` and
   Spark `{high, low}`, while the reference, the 35B and the `David AU` 27B read nothing
   (`llama-bench-runner/measurements/reasoning-effort-templates.md`). **No variant is created**:
   it is sent by `pi` (`PI_EXTRA='--thinking <tier>'`) and the factory is the place that will
   eventually send it, so nothing has to change on the host. It is **not** swept per role — it
   is offered for the tests that run into the ceiling. Open: measure Spark at `low` against the
   `high` its template defaults to, then repeat at the top tier on a served 27B.
