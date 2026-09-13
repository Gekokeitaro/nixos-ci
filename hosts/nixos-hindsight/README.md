# nixos-hindsight

[Hindsight](https://github.com/vectorize-io/hindsight) — an AI-powered data
platform with built-in vector search, using OmniRoute as its LLM backend and
PostgreSQL (`nixos-postgresql`) as its database.

## Build

```bash
nixos-rebuild build-image --image-variant lxc --flake .#nixos-hindsight
```

## Exposed ports

| Service | Port |
|---|---|
| Hindsight | 8888, 9999 |

## Dependencies

- `nixos-omniroute` at `http://192.168.18.32:20128/v1` — LLM provider
  (OpenAI-compatible, model `static-best-free`).
- `nixos-postgresql` at `192.168.18.60:5432` — DB `hindsight` with pgvector.

## Secrets

`sops-nix` manages `hindsight-env`:
- `sopsFile = ./secrets/hindsight-env.env` (dotenv format), mode `0444`.
- Injected via `environmentFiles`; contains additional runtime secrets
  (API keys, etc.) not in `configuration.nix`.

The database password lives in `common/secrets/postgresql-shared.yaml`
(shared with `nixos-postgresql`).

## First boot

1. Ensure `nixos-postgresql` is up with the `hindsight` DB and pgvector.
2. Ensure `nixos-omniroute` is up and serving models.
3. Import the tarball, create and start the LXC.
4. Open `http://<IP>:8888` in a browser.

## SSH

```bash
ssh nixos-hindsight@<IP>
```

## Apply changes

Remote:

```bash
nixos-rebuild switch --flake .#nixos-hindsight --target-host <user>@<ip> --elevate=sudo
```

Inside the container:

```bash
sudo nixos-rebuild switch --flake .#nixos-hindsight
```
