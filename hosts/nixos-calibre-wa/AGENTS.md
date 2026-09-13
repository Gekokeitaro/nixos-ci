# AGENTS.md — nixos-calibre-wa

Context guide for LLM agents working on the `nixos-calibre-wa` host.

## Purpose

Serves Calibre-Web-Automated (CWA): Calibre-Web UI + Calibre engine +
auto-ingest in one OCI container. The ebook library lives on pCloud,
mounted locally via rclone+FUSE and seen as a normal directory.

## Services & ports

| Service | Port | Notes |
|---|---|---|
| Calibre-Web-Automated (OCI) | 8083 | UI, `docker.io/crocodilestick/calibre-web-automated:latest` |
| rclone-pcloud (systemd) | — | Mounts `pcloud:` at `/mnt/pcloud`, `Type=notify` |

## Dependencies

- pCloud remote configured via rclone; token stored in sops secret
  (`token =` inside the rclone conf). Renew with
  `rclone authorize "pcloud"` and re-encrypt.
- `/dev/fuse` on Proxmox host (see Constraints) — REQUIRED for rclone mount.
- Podman volume dirs under `/home/nixos-calibre-web-auto/.config/calibre-web-automated/`.

## Secrets

sops-nix with `age.keyFile = "/home/nixos-calibre-web-auto/.config/sops/age/keys.txt"`:
- `rclone-pcloud-conf` — `sopsFile = ./secrets/calibre-wa.yaml`, mode `0444`.

## Special config

- OCI container volumes: `/config`, `/config/.config/calibre/plugins`,
  `/mnt/pcloud:/calibre-library`.
- `PUID=1000`, `PGID=1000`, `TZ=Europe/Madrid`.
- Boot order enforced: `podman-calibre-web-automated` has
  `after` + `requires` on `rclone-pcloud.service` (avoids statfs race).
- `programs.fuse.userAllowOther = true` (needed for container access to the
  FUSE mount).
- tmpfiles create `/mnt/pcloud` and config/plugins dirs.
- rclone flags: `--vfs-cache-mode writes`, `--allow-other`; runs as root.
- User `nixos-calibre-web-auto` with rclone + fuse3 CLI tools.

## Constraints

- Unprivileged LXC. FUSE requires manual lines in the Proxmox container conf
  (`/etc/pve/lxc/<id>.conf`):
  - `lxc.cgroup2.devices.allow: c 10:229 rwm` (`10:229` = `/dev/fuse`)
  - `lxc.mount.entry: /dev/fuse dev/fuse none bind,create=file 0 0`
- Without those lines, `rclone mount` fails with "Permission denied" opening
  `/dev/fuse`.

## Modification guide

- To change the pCloud remote/token: update `secrets/calibre-wa.yaml` with sops
  (re-encrypt after `rclone authorize "pcloud"`).
- To switch library mount path: adjust the `volumes` entry and the rclone
  `ExecStart` mountpoint consistently.
- `systemd.services.rclone-pcloud` restarts on failure (`Restart=on-failure`,
  `RestartSec=5s`) — network drops are handled automatically.