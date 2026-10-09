# AGENTS.md — nixos-pi-agent

Context guide for LLM agents working on the `nixos-pi-agent` host.

## Purpose

Coding agent session host with n8n integration. Runs the
`pi-coding-agent` tool which connects to a remote llama-swap
instance for AI inference.

## Services & ports

No TCP services are opened. The agent connects outbound to
llama-swap at `http://192.168.18.12:8080/v1`.

## Dependencies

- `pi-coding-agent` Nix package — installed and wrapped via
  `environment.systemPackages`.
- Remote `llama-swap` at `http://192.168.18.12:8080` — provides
  the AI inference backend.
- `nodejs`, `ripgrep`, `fd` — runtime dependencies for the wrapped
  `pi` binary.
- `config/models.json` and `config/settings.json` — copied into
  the agent directory on boot.

## Secrets

No sops-nix configuration. The llama-swap API key in `models.json`
is a `dummy-key` placeholder; real credentials should be managed
outside this configuration.

## Special config

- `piCodingAgent.enable = true` in `configuration.nix`.
- `modelsPath = ./config/models.json` — providers and models
  definition (currently one provider: `llama-swap` at `192.168.18.12:8080`).
- `settingsPath = ./config/settings.json` — default provider,
  model (`gpt-oss-20b-NEO-IQ4_NL`), thinking level (`medium`),
  and retry settings (3 max retries).
- `extensions = []` — list of extension files symlinked to
  `~/.pi/agent/extensions/`. The `extensions/` directory exists
  but is currently empty.
- `NPM_CONFIG_PREFIX` set to `~/.pi/agent/npm/` for npm-based
  extension installation.
- User `nixos-pi-agent` with `extraGroups = ["wheel"]`, SSH keys
  (PopOS OCT 2024, NixOS-CI MAY 2026).
- `nix.settings.trusted-users = ["nixos-pi-agent"]` + experimental
  features (`nix-command`, `flakes`).
- Module creates `systemd.tmpfiles.rules` for `~/.pi/agent/`
  directories and symlinks config files.

## Constraints

- Unprivileged LXC (no privileged features).
- SSH keys must be present in `configuration.nix` before building
  the image or remote deployment will fail.
- The agent depends on an external `llama-swap` instance at
  `192.168.18.12:8080`; if the endpoint changes, update
  `config/models.json`.
- Configuration files do not travel to the image — after creating
  the container, run `nix-channel --update` and re-clone the
  configuration inside it.

## Modification guide

### Adding an extension (via files)

1. Place the extension file in `extensions/`.
2. Add its path to `piCodingAgent.extensions` in
   `configuration.nix`.
3. Re-apply the configuration.

### Adding an extension (via npm)

```bash
pi extensions install <package-name>
```

> **Known issue:** `pi extensions install` may fail with
> `EACCES: permission denied` inside the LXC container due to
> npm permissions on `~/.pi/agent/npm/`. Workaround: pre-install
> extensions on the host and copy into `extensions/`, or fix
> directory ownership before running the install. See related
> issue for a permanent fix.

### Changing the llama-swap endpoint or models

1. Edit `config/models.json` with the new provider URL and
   model list.
2. Re-apply: `nixos-rebuild switch --flake .#nixos-pi-agent`.

### Updating default settings

Edit `config/settings.json` for changes to `defaultModel`,
`defaultThinkingLevel`, or `retry` configuration.
