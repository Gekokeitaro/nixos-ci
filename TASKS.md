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
5. Verify the fragment-library refactor post hoc: it reached the host with the
   2026-11-15 deploy, so compare the served model ids and the rendered
   llama-swap config on the host against `e52c157`, the last commit before the
   refactor. Same ids and same `cmd` text means the refactor rendered identical.
   Later deploys moved the host past that point, so today's rendering also
   carries `e9d4069` and everything after it; the comparison now needs
   `e52c157` rendered rather than read from the host.
