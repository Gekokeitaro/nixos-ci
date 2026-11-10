# nixos-pi-agent

Coding-agent session host. Runs `pi-coding-agent` with inference through
OmniRoute; n8n can SSH in and launch sessions.

## Module options

The `piCodingAgent` module (`modules/pi-coding-agent/default.nix`) provides:

| Option | Type | Default | Description |
|---|---|---|---|
| `piCodingAgent.enable` | boolean | `false` | Enables the pi-coding-agent setup |
| `piCodingAgent.modelsPath` | `path` | `./config/models.json` | Path copied to `~/.pi/agent/models.json` |
| `piCodingAgent.settingsPath` | `path` | `./config/settings.json` | Path copied to `~/.pi/agent/settings.json` |
| `piCodingAgent.extensions` | `list of path` | `[]` | Extension files symlinked to `~/.pi/agent/extensions/` |

When `enable = true`, the module:

1. Installs `pi-coding-agent` via `environment.systemPackages`, wrapping `pi`
   with `nodejs`, `ripgrep`, and `fd` on `PATH`, and setting
   `NPM_CONFIG_PREFIX`, `PI_SKIP_VERSION_CHECK`, and `PI_TELEMETRY`.
2. Creates `~/.pi/agent/` directories via `systemd.tmpfiles.rules`.
3. Symlinks `modelsPath` → `~/.pi/agent/models.json` and copies
   `settingsPath` → `~/.pi/agent/settings.json` (also refreshed by the
   `pi-agent-sync` service on boot).
4. Symlinks each entry in `extensions` into `~/.pi/agent/extensions/`.

## Configuration

**`config/models.json`** — one provider named `llama-swap` pointing at OmniRoute
(`http://192.168.18.32:20128/v1` in [INFRA.md](../../INFRA.md), API `openai-completions`):

| Model id | Context |
|---|---|
| `llamacpp/Gemma 4 12B QAT UD Q4_K_XL` | 262144 |
| `llamacpp/OmniCoder-9B Q5_K_M DFlash` | 262144 |
| `llamacpp/Qwen3.5 9B UD Q4_K_XL` | 262144 |
| `llamacpp/Qwen3.8 27B GSQ-RCO IQ3_XXS MTP` | 131072 |

> [!WARNING]
> The API key is stored in plaintext in `models.json` (not sops). The file also
> has a double slash in the base URL (`...:20128//v1`) in the current version.

**`config/settings.json`** — runtime defaults:

- `theme`: `dark`
- `defaultProvider`: `llama-swap`
- `defaultModel`: `gpt-oss-20b-NEO-IQ4_NL` (not in the model catalog above)
- `defaultThinkingLevel`: `medium`
- `packages`: `pi-skills`, `npm:pi-powerline-footer`, `npm:@luxusai/pi-hindsight`,
  `npm:pi-web-access`

## Build

```bash
nixos-rebuild build-image --image-variant lxc --flake .#nixos-pi-agent
```

## Exposed ports

No TCP ports opened. The agent connects outbound to OmniRoute at
`http://192.168.18.32:20128/v1` in [INFRA.md](../../INFRA.md).

## First boot

1. Import the tarball as LXC template in Proxmox and create the container.
2. Ensure the host can reach `192.168.18.32:20128` (OmniRoute) in [INFRA.md](../../INFRA.md).
3. Start the container.
4. Confirm `pi --version` works.
5. Verify the agent directories: `ls ~/.pi/agent/`.

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

## Notes

- This host is not covered by the automatic `llamaswap-rocm` deployment
  workflow; apply it manually.
- `pi extensions install` may still hit npm permission issues inside the LXC.
  Prefer declaring packages in `settings.json` or symlinking files through
  `piCodingAgent.extensions`.
