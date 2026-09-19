# nixos-pi-agent

LXC container running pi-coding-agents sessions with n8n workflow integration.

## Architecture

### Structure

```
hosts/nixos-pi-agent/
├── configuration.nix          # NixOS host config; imports common + pi-coding-agent module
├── default.nix                # Entry point (if needed)
├── modules/pi-coding-agent/default.nix  # NixOS module: wrap, extensions, tmpfiles
├── config/
│   ├── models.json            # Custom LLM providers (read-only via tmpfiles L+)
│   └── settings.json          # Pi global settings (copied on first boot via tmpfiles C)
├── extensions/                # Local .ts extensions auto-discovered by pi
├── pi/                        # Legacy scripts
├── AGENTS.md
└── README.md
```

### Configuration flow

1. **`flake.nix`** → `./hosts/nixos-pi-agent/configuration.nix`
2. **`configuration.nix`** imports `../../common` and `./modules/pi-coding-agent/default.nix`
3. **`modules/pi-coding-agent/default.nix`** provides:
   - `pi-coding-agent` wrapped with `makeWrapper` (adds `nodejs`, `ripgrep`, `fd` to PATH; sets `NPM_CONFIG_PREFIX`)
   - All `systemd.tmpfiles.rules` (directories, config file symlinks, extension symlinks)
4. **`configuration.nix`** provides:
   - User `nixos-pi-agent` definition
   - `piCodingAgent.enable = true`, `modelsPath`, `settingsPath`, `extensions` list

### Extension types

| Type | Location | How pi loads |
|------|----------|-------------|
| **Local** | `extensions/*.ts` | Auto-discovered via symlink to `~/.pi/agent/extensions/` |
| **npm** | `settings.json` `packages` | Installed by `pi` via npm (requires `nodejs` wrapper) |

### npm support

The `pi-coding-agent` binary is wrapped with `makeWrapper` to include:
- `nodejs` in PATH (required for npm-based extensions)
- `NPM_CONFIG_PREFIX` pointing to `~/.pi/agent/npm/` (avoids writing to the Nix store)

This resolves the NixOS `npm ENOENT` issue where `pi install npm:...` fails because npm tries to write to the immutable Nix store.

## Build

```bash
nixos-rebuild build-image --image-variant lxc --flake .#nixos-pi-agent
```

## Exposed ports

| Service | Port |
|---------|------|
| pi-coding-agents API | TBD |
| Agent WebSocket | TBD |

Ports are controlled by `networking.firewall.allowedTCPPorts` in the host configuration.

## Dependencies

- **nixos-n8n** at `192.168.18.61:5678` for workflow orchestration
- PostgreSQL for session state management (may use shared `nixos-postgresql`)

## Secrets

- `agent_api_token` — sops-managed secret for authentication
- `n8n_auth_token` — shared auth token for n8n integration

Both secrets are injected into the pi-coding-agents container at first boot.

## First boot

1. Ensure all dependencies are operational:
   - `nixos-n8n` is up and running
   - PostgreSQL database for sessions exists (if used)

2. Import the tarball as template in Proxmox, create and start the LXC:
   ```
   System resources: 1–2 CPU, 2–4 GB RAM, 10–20 GB disk
   ```

3. Verify the pi-coding-agents service is running:
   ```bash
   systemctl status pi-coding-agents.service
   ```

4. Check logs if needed:
   ```bash
   journalctl -u pi-coding-agents.service
   ```

## SSH

```bash
ssh nixos-pi-agent@<IP>
```

## Apply changes

### Remote (on the host)

```bash
nixos-rebuild switch --flake .#nixos-pi-agent --target-host <user>@<IP> --elevate=sudo
```

### Inside the container

```bash
sudo nixos-rebuild switch --flake .#nixos-pi-agent
```

## Adding extensions

### Local extensions

Place `.ts` files in `extensions/`. They will be symlinked to `~/.pi/agent/extensions/` on boot via `systemd.tmpfiles`. Pi auto-discovers them.

### npm extensions

Add to `settings.json` under `packages`. Requires `nodejs` to be available (already handled by the wrapper). Note: auto-install on startup is not guaranteed (see [pi Issue #5421](https://github.com/earendil-works/pi/issues/5421)).

## Notes

- This host follows the same conventions as all other LXC containers in the repository: unprivileged execution, sops-nix for secrets, OCI or native NixOS services.
- pi-coding-agent packages are managed by the `modules/pi-coding-agent/default.nix` module, not by `environment.systemPackages`.
