# nixos-n8n-runner

LXC running n8n task runners. Each runner connects to the `nixos-n8n` broker,
executes a single task, then shuts down after an inactivity timeout (15s).

## Build

```bash
nixos-rebuild build-image --image-variant lxc --flake .#nixos-n8n-runner
```

## Exposed ports

| Service | Port |
|---|---|
| Runner container default | 20128 |

## Dependencies

- `nixos-n8n` broker at `http://192.168.18.22:5678`.
- Auth token shared with `nixos-n8n` (sops-managed).

## Secrets

- `n8n_runner_auth_token` — `./secrets/auth-env.yaml` (sops, dotenv format).
  Injected via `environmentFiles`; the env var name is `N8N_RUNNERS_AUTH_TOKEN`.

## First boot

1. Import the tarball as template in Proxmox, create and start the LXC
   (1 CPU, 1–2 GB RAM, 5–10 GB disk — runners are lightweight).
2. Confirm runners start: `podman ps` should show the `n8n-task-runners`
   container.
3. Run a workflow in `nixos-n8n` that uses an external runner — the runner
   should pick up the task automatically.

## SSH

```bash
ssh nixos-n8n-runner@<IP>
```

## Apply changes

Remote:

```bash
nixos-rebuild switch --flake .#nixos-n8n-runner --target-host <user>@<ip> --elevate=sudo
```

Inside the container:

```bash
sudo nixos-rebuild switch --flake .#nixos-n8n-runner
```

## Notes

- `N8N_RUNNERS_AUTO_SHUTDOWN_TIMEOUT = "15"` — runners exit 15s after task
  completion. Set to `"0"` to disable auto-shutdown.
- The auth token must match in both `hosts/nixos-n8n/secrets.yaml` and
  `hosts/nixos-n8n-runner/secrets/auth-env.yaml` when rotating.
