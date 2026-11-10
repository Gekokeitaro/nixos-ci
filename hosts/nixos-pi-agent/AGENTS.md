# AGENTS.md — nixos-pi-agent

Context guide for LLM agents working on the `nixos-pi-agent` host.

## Purpose

Coding-agent session host. Runs the `pi-coding-agent` tool, which sends
inference to an OpenAI-compatible endpoint served by `nixos-omniroute`. The
`nixos-n8n` key is authorized, so n8n can SSH in and launch sessions.

## Services & ports

No TCP services are opened. The agent connects outbound to OmniRoute at
the endpoint listed in [INFRA.md](../../INFRA.md) (`v1` OpenAI-compatible).

## Dependencies

- `pi-coding-agent` Nix package, wrapped via `environment.systemPackages`.
- `nixos-omniroute` (`192.168.18.32:20128` in [INFRA.md](../../INFRA.md)) as the inference backend.
- `nodejs`, `ripgrep`, and `fd` — runtime dependencies added to the wrapped
  `pi` binary's `PATH`.
- `config/models.json` — provider and model catalog.
- `config/settings.json` — runtime defaults and npm packages.

## Secrets

No sops-nix configuration. `config/models.json` currently contains a plaintext
API key for the OmniRoute endpoint; it is not managed by sops. Do not copy the
key into documentation or logs.

## Special config

- `piCodingAgent.enable = true` in `configuration.nix`.
- `modelsPath = ./config/models.json`; `settingsPath = ./config/settings.json`;
  `extensions = []` (no extension files are symlinked).
- `models.json`: one provider named `llama-swap` whose `baseUrl` points to
  OmniRoute (`192.168.18.32:20128` in [INFRA.md](../../INFRA.md)) , path `//v1` in the current file), API
  `openai-completions`. Models:
  - `llamacpp/Gemma 4 12B QAT UD Q4_K_XL` (262144 context)
  - `llamacpp/OmniCoder-9B Q5_K_M DFlash` (262144)
  - `llamacpp/Qwen3.5 9B UD Q4_K_XL` (262144)
  - `llamacpp/Qwen3.8 27B GSQ-RCO IQ3_XXS MTP` (131072)
- `settings.json`: `theme = "dark"`, `defaultProvider = "llama-swap"`,
  `defaultModel = "gpt-oss-20b-NEO-IQ4_NL"` (not present in `models.json`),
  `defaultThinkingLevel = "medium"`, and npm `packages` (`pi-skills`,
  `pi-powerline-footer`, `@luxusai/pi-hindsight`, `pi-web-access`).
- The module wraps `pi` with `NPM_CONFIG_PREFIX=~/.pi/agent/npm/`,
  `PI_SKIP_VERSION_CHECK=1`, and `PI_TELEMETRY=0`.
- `systemd.tmpfiles.rules` creates `~/.pi/agent/` directories, symlinks
  `models.json`, and copies `settings.json`; `pi-agent-sync` copies settings on
  boot.
- User `nixos-pi-agent` with `extraGroups = ["wheel"]` and three SSH keys
  (PopOS OCT 2024, NixOS-CI MAY 2026, nixos-n8n SEP 2026).
- `nix.settings.trusted-users = ["nixos-pi-agent"]` and experimental features
  (`nix-command`, `flakes`).

## Constraints

- Unprivileged LXC (no privileged features).
- SSH keys must be present in `configuration.nix` before building the image or
  remote deployment will fail.
- The agent depends on OmniRoute at `192.168.18.32:20128` in [INFRA.md](../../INFRA.md); if it moves, update
  `config/models.json`.
- The `defaultModel` in `settings.json` is not in the current model catalog.
  Verify it before relying on the default.
- The API key is plaintext in `models.json`; moving it to sops is pending.
- The automatic deployment workflow only covers `nixos-llamaswap-rocm`; this
  host is applied manually.

## Modification guide

### Change the endpoint or models

1. Edit `config/models.json` with the new provider URL and model list.
2. Re-apply: `nixos-rebuild switch --flake .#nixos-pi-agent`.

### Change defaults

Edit `config/settings.json` (`defaultModel`, `defaultThinkingLevel`, `theme`,
`packages`). The module copies this file into `~/.pi/agent/settings.json` on
boot.

### Add a file-based extension

1. Put the extension file under `hosts/nixos-pi-agent/` (create a directory if
   you want to keep them together).
2. Add its path to `piCodingAgent.extensions` in `configuration.nix`.
3. Re-apply the configuration.

### Install runtime packages

Add them to the `packages` array in `config/settings.json`. The module sets
`NPM_CONFIG_PREFIX` so `pi` installs them under `~/.pi/agent/npm/`.
