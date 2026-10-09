# nixos-pi-agent

Coding agent session host with n8n integration. Serves as a
pi-coding-agent container that connects to llama-swap for AI inference.

## Module options

The `piCodingAgent` module (`modules/pi-coding-agent/default.nix`) provides
the following options:

| Option | Type | Default | Description |
|---|---|---|---|
| `piCodingAgent.enable` | boolean | `false` | Enables the pi-coding-agent service |
| `piCodingAgent.modelsPath` | `path` | `./config/models.json` | Path to `models.json` copied to `~/.pi/agent/models.json` |
| `piCodingAgent.settingsPath` | `path` | `./config/settings.json` | Path to `settings.json` copied to `~/.pi/agent/settings.json` |
| `piCodingAgent.extensions` | `list of path` | `[]` | Extension files symlinked to `~/.pi/agent/extensions/` |

Extensions can also be installed via npm. The module configures
`NPM_CONFIG_PREFIX` to `~/.pi/agent/npm/`, so extensions are
installed with:

```bash
pi extensions install <package-name>
```

> **Known issue:** `pi extensions install` may fail with
> `EACCES: permission denied` inside the LXC container due to
> npm permissions on the `~/.pi/agent/npm/` directory. A workaround
> is to pre-install extensions on the host and copy them into
> `extensions/` as files symlinked via `piCodingAgent.extensions`,
> or to fix directory ownership before running the install. Track
> the related issue for a permanent fix.

When `enable = true`, the module:

1. Installs `pi-coding-agent` via `environment.systemPackages`, wrapping the
   `pi` binary with `PATH` including `nodejs`, `ripgrep`, and `fd`, and setting
   `NPM_CONFIG_PREFIX` and telemetry flags.
2. Creates directories under `~/.pi/agent/` via `systemd.tmpfiles.rules`.
3. Symlinks `modelsPath` → `~/.pi/agent/models.json` and `settingsPath` →
   `~/.pi/agent/settings.json` using tmpfiles `L+` and `C` rules.
4. Symlinks each extension path to `~/.pi/agent/extensions/<name>` for every
   entry in `extensions`.

### Configuration files

**`config/models.json`** — Defines the AI providers and available models.
Currently configured with a single `llama-swap` provider at
`http://192.168.18.12:8080/v1` offering four models:
Gemma 4 12B, Qwen3.5 9B, OmniCoder-9B, and Qwen3.8 27B.

**`config/settings.json`** — Sets runtime defaults:
- `defaultProvider`: `llama-swap`
- `defaultModel`: `gpt-oss-20b-NEO-IQ4_NL`
- `defaultThinkingLevel`: `medium`
- `retry`: enabled with 3 max retries

## Build

```bash
nixos-rebuild build-image --image-variant lxc --flake .#nixos-pi-agent
```

## Exposed ports

No TCP ports opened by default. The pi-coding-agent connects outbound to
llama-swap at `http://192.168.18.12:8080/v1`.

## First boot

1. Import the tarball as LXC template in Proxmox and create the container.
2. Ensure the host can reach `192.168.18.12:8080` (llama-swap endpoint).
3. Start the container.
4. Confirm the `pi` binary is available: `pi --version`.
5. Verify the agent directories are created: `ls ~/.pi/agent/`.

## SSH

```bash
ssh nixos-pi-agent@<IP>
```

## Apply changes

Remote:

```bash
nixos-rebuild switch --flake .#nixos-pi-agent --target-host <user>@<ip> --elevate=sudo
```

Inside the container:

```bash
sudo nixos-rebuild switch --flake .#nixos-pi-agent
```
