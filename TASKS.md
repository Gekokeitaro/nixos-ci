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
5. **The 35B serves 163840 from the six roles, and its baseline is stale.** `--ctx-size 163840`
   (ceiling 196608 at load; 229376 misses by 34 MiB) with the battery in its header. The CORE
   `k=3` of 2026-11-20 gave **45/96** (`cross` 12/12, `planner` 2/12), but it was taken with
   `default = agent`; the file now serves `profiles.roles` and nothing inherited, so the bare
   id runs on llama.cpp's server defaults and **that CORE has to be repeated** as its real
   baseline. Threads are settled (`-t 1`: `pp512` 348, `pp4096` 302). **The spec is closed**:
   no MTP layers, and `ngram-mod`'s best triple peaks at 1.014× for ~300 MiB, so the entry
   serves `--spec-type none` — there is nothing left to try on it.
   **Not deployed yet.**
6. **`reasoning_effort` is a lever, and it travels from the client (decided 2026-11-20).** It
   exists only where the GGUF template implements it: the 27B base quants and two served 27B
   entries (`Ukisai Swift 1.5`, `Ternary Bonsai 2 27B`) declare `{xhigh, medium, low}` and
   Spark `{high, low}`, while the reference, the 35B and the `David AU` 27B read nothing
   (`llama-bench-runner/measurements/reasoning-effort-templates.md`). **No variant is created**:
   it is sent by `pi` (`PI_EXTRA='--thinking <tier>'`) and the factory is the place that will
   eventually send it, so nothing has to change on the host. It is **not** swept per role — it
   is offered for the tests that run into the ceiling. Open: measure Spark at `low` against the
   `high` its template defaults to, then repeat at the top tier on a served 27B.
