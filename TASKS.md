# TASKS.md — nixos-ci

Open work of this repository. A task is deleted when it lands; what it taught
moves to the file that owns it.

## Pending

0. **The Vulkan profile is the fallback this host may need, and it is unstable.**
   `nixos-llamaswap-vulkan` exists and is applied by hand (it is the second flake output of the
   same `configuration.nix`), so switching the model host to Vulkan is a decision, not a rebuild.
   The reason to keep it on the table: at least one family we want to serve **aborts on ROCm with
   our GPU class** — PrismML's ternary Bonsai says so in its own `KNOWN_ISSUES.md` (*“ROCm/HIP aborts
   on consumer RDNA2 GPUs (for example gfx1030)”*, status open, no HIP workaround, *try the Vulkan
   build*), and this host is `gfx1035` presented as `gfx1030`. The reason not to switch today: the
   Vulkan profile has been the unstable one, and nothing here has measured it since the
   llama.cpp 1.0.0 batteries. **What changed is that the workspace can now attack that**: the
   battery, `spec-bench`, the context grid, the health gate (`tg` against a per-GGUF baseline) and
   the `dmesg` page-fault signature all exist, so instability can be measured instead of argued
   about. Task: one GGUF (the reference 9B, whose ROCm numbers are the yardstick), the same battery
   on both profiles, the same health gate, and a fault/tg64 table over a multi-hour run. Only then
   is a model with no ROCm path — Bonsai, or anything else that aborts — served on Vulkan.

0. **Roles for the parity run, prepared 2026-11-23 (pending deploy).** The six roles from
   `modelLib.profiles.roles` are now declared on `Unsloth-gemma-4-12B-…` (replacing its
   instruct-only filter), `Unsloth-gemma-4-E4B-…`, `DavidAU-Qwen3.8-27B-…` and
   `Ukisai-Swift-1.5-Qwen3.8-27B-…` (the last keeps its bare id on `profiles.thinking` with
   presence 0). Their bare ids keep the sampling their `cmd` carries. Sampler research for the
   family, 2026-11-23: Qwen3.8 card `1.0/0.95/20` thinking and `0.7/0.80/20` instruct; DavidAU
   tester settings `temp .5-1, top_k 64, min_p .05, top_p .95` and tools at `.6-.7`; Gemma 4 card
   `1.0/0.95/64` (four independent sources). The roles still use the library's geometry until
   session 8b tunes them per model.
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
5. **The 35B is served and its roles are baselined.** `--ctx-size 163840` (ceiling 196608, re-measured
   with the spec inside: 13681 MiB, 655 MiB of margin), `-t 1`, `-b 2048 -ub 512`, **ngram-mod
   24:32:48 universal**, the six roles with budgets and the forced message, and a bare id pinned to
   the vendor `thinking` preset since 2026-11-22 (`6e4f369`). No MTP: the GGUF carries none.
   CORE `k=3`: **54/96** — `supervisor` 23/30, `integrator` 4/6, `cross` 9/12, `planner`
   4/12, `implementer` 11/30, `reviewer` 3/6 (`ai-tests/measurements/qwen3.6-35b-a3b-reap-48-v2.md`).
   **Closed 2026-11-22: `cross` reads 12/12 → 9/12 → 11/12 → 11/12 and the last two are the
   same 12 rows under the same no-filter config, so the wobble was repetition noise on `t07`,
   not the sampler.** The pinned `thinking` id ties at 11/12. That 54/96 was taken on the
   **no-filter** bare id, so the six role rows stand and the bare id owes a fresh CORE; nothing
   else is owed on it.
6. **`reasoning_effort` is a lever, and it travels from the client (decided 2026-11-20).** It
   exists only where the GGUF template implements it: the 27B base quants and two served 27B
   entries (`Ukisai Swift 1.5`, `Ternary Bonsai 2 27B`) declare `{xhigh, medium, low}` and
   Spark `{high, low}`, while the reference, the 35B and the `David AU` 27B read nothing
   (`llama-bench-runner/measurements/reasoning-effort-templates.md`). **No variant is created**:
   it is sent by `pi` (`PI_EXTRA='--thinking <tier>'`) and the factory is the place that will
   eventually send it, so nothing has to change on the host. It is **not** swept per role — it
   is offered for the tests that run into the ceiling. **Spark's `low` has been measured** —
   `0 of 9` on `t04`/`t05`/`t12` over `:implementer`, nine timeouts, so the cheap tier does not
   stop that loop and the budget remains the brake (`ai-tests/measurements/spark.md`). Open: the
   clean single-knob pair on the bare id at `high` against `low`, and the top tier on a served 27B.
7. **Apply and measure the `pi` LoRA on the Qwen3.8 27B entries (noted 2026-11-23).**
   `/models/Qwen3.8-27B-pi-lora-F16.gguf`, 318,802,304 B, sha256
   `a64f91844f19e67da500d8628bdf9383aa334e61b7ab687805802e7d272d7b67`, `adapter.type lora`,
   FFN-only tensors, `general.architecture = qwen35` — the architecture all three served 27B GGUFs
   report. Plan: add `--lora /models/Qwen3.8-27B-pi-lora-F16.gguf` to the `cmd` of
   `DavidAU-Qwen3.8-27B-TBrill-50X-…` and `Ukisai-Swift-1.5-Qwen3.8-27B-…`; the Prism ternary
   entry only after the first two show a win. Measure it as a candidate, same GGUF at scale 0
   against 1.0, CORE or the role suites against its own baseline, never mixed with another knob.
   The two-arm A/B can avoid a redeploy with `--lora-init-without-apply` plus
   `POST /upstream/<model>/lora-adapters` once that POST is proven through llama-swap. Procedure:
   `skills/model-files/references/lora-adapters.md`. **Applied 2026-11-23 at scale 1.0 in both
   entries**; the deploy is the one pending. After it: prove the POST, then measure scale 0
   against scale 1 on the same tests (the bare id has no role suite, so start with `--triage` on
   the DavidAU entry and only spend a CORE if it does not lose).
