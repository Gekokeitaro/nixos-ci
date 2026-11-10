# INFRA.md — network and service inventory

> Canonical source for host addresses, exposed ports, and service
> dependencies. Update this file when a host moves or a port changes. Host
> documentation links here instead of repeating addresses. Deployed state and
> pending work live in [MEMORY.md](./MEMORY.md); architecture and rules live in
> [AGENTS.md](./AGENTS.md).

Last verified: 2026-11-10.

## Hosts

| Host | Role | Address | Inbound ports | Depends on |
|---|---|---|---|---|
| `nixos-ci` | Build host + Forgejo runners | `192.168.18.10` | none | `nixos-forgejo` (`192.168.18.31:3000`) |
| `nixos-forgejo` | Forgejo + Actions | `192.168.18.31` | 3000 | none |
| `nixos-llamaswap-rocm` | llama-swap + llama.cpp (ROCm) | `192.168.18.11` | 8080 | Proxmox GPU passthrough |
| `nixos-llamaswap-vulkan` | llama-swap + llama.cpp (Vulkan) | — | 8080 | Proxmox GPU passthrough |
| `nixos-omniroute` | OmniRoute AI gateway | `192.168.18.32` | 20128 | none |
| `nixos-hindsight` | Hindsight data platform | `192.168.18.19` | 8888, 9999 | OmniRoute, PostgreSQL |
| `nixos-n8n` | n8n automation | `192.168.18.22` | 5678, 5679 | PostgreSQL |
| `nixos-n8n-runner` | n8n task runners | — | 20128 | `nixos-n8n` (`192.168.18.22:5678`) |
| `nixos-postgresql` | PostgreSQL + pgvector | `192.168.18.91` | 5432 | none |
| `nixos-pi-agent` | `pi` coding agent | — | none | OmniRoute (`192.168.18.32:20128`) |
| `nixos-calibre-web-auto` | Calibre-Web-Automated + rclone | — | 8083 | pCloud, `/dev/fuse` |
| `pihole-lxc` | Pi-hole (legacy) | — | — | Not wired into `flake.nix` |

`—` means the address or port is not recorded in the repository. Read it from
Proxmox or the host's network configuration and add it here once known.

## Service dependencies

- `nixos-ci` → `nixos-forgejo`: runner registration and Actions.
- `nixos-hindsight` → `nixos-omniroute`: LLM provider (`/v1`).
- `nixos-hindsight` → `nixos-postgresql`: database `hindsight` with pgvector.
- `nixos-n8n` → `nixos-postgresql`: database `n8n`.
- `nixos-n8n-runner` → `nixos-n8n`: task broker.
- `nixos-pi-agent` → `nixos-omniroute`: LLM provider (`/v1`).
- `nixos-calibre-web-auto` → pCloud via rclone/FUSE.

## Change checklist

When an address or port changes:

1. Update this file.
2. Update the matching Nix configuration (SSH aliases, runner URLs,
   PostgreSQL `authentication`, OCI env, or `models.json`).
3. Update `MEMORY.md` if the deployed state changes.
4. Search for the old value in the repository; do not leave stale copies in
   host docs or READMEs.
