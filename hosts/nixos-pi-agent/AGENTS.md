# AGENTS.md — nixos-pi-agent

Context guide for LLM agents working on the `nixos-pi-agent` host. See the
[repository guide](../AGENTS.md) for shared NixOS conventions.

## Purpose

LXC container running pi-coding-agents sessions with n8n workflow integration.
The container provides interactive coding-agent environments that n8n workflows
can spawn, control, and monitor.

## Architecture

```text
nixos-n8n (workflow orchestration)
    ↕ API / broker
nixos-pi-agent (coding-agent sessions)
```

The host is built declaratively using a modular architecture:
- `configuration.nix` — host definition, user, SSH keys, tmpfiles for config files
- `modules/pi-coding-agent/default.nix` — NixOS module: wraps `pi-coding-agent` with `makeWrapper` (nodejs, ripgrep, fd, NPM_CONFIG_PREFIX), manages extension symlinks and tmpfiles
- `config/` — `models.json` (providers) and `settings.json` (global settings)
- `extensions/` — local `.ts` extensions auto-discovered by pi

## Goals

- Run pi-coding-agents sessions as isolated environments
- Expose an API for n8n workflows to create, inspect, and terminate sessions
- Preserve interactive coding-agent communication through a WebSocket endpoint
- Store session metadata and state without requiring privileged container access

## Constraints

- Follow the shared [repository guide](../AGENTS.md)
- Keep the host unprivileged and compatible with Proxmox LXC
- Do not assume access to host devices or privileged cgroup operations
- Keep `flake.nix` thin; implement host logic in `configuration.nix`
- Use sops-nix for credentials and never commit secrets
- Prefer OCI or native NixOS services over custom shell scripts

## Extension management

- **Local extensions**: Place `.ts` files in `extensions/`. They are symlinked
  to `~/.pi/agent/extensions/` via `systemd.tmpfiles.rules` and auto-discovered by pi.
- **npm extensions**: Listed in `settings.json` under `packages`. Requires `nodejs`
  (handled by the wrapper). Auto-install on startup is not guaranteed
  (see [pi Issue #5421](https://github.com/earendil-works/pi/issues/5421)).

## Configuration files

- `config/models.json` — Custom LLM providers (read-only symlink to `~/.pi/agent/models.json`)
- `config/settings.json` — Pi global settings (copied on first boot to `~/.pi/agent/settings.json`)
- `~/.pi/agent/npm/` — npm packages installed by pi (writable via NPM_CONFIG_PREFIX)

## Unknowns to resolve before implementation

- n8n API or broker protocol
- Ports, session persistence, and resource limits
- Authentication and authorization boundaries between n8n and the agent host
