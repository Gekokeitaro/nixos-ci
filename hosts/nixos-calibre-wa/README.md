# nixos-calibre-wa

LXC for Calibre-Web-Automated (CWA) with the ebook library synced to pCloud.
See: https://github.com/crocodilestick/Calibre-Web-Automated

## Build

```bash
nixos-rebuild build-image --image-variant lxc --flake .#nixos-calibre-web-auto
```

> [!NOTE]
> The flake output key is `nixos-calibre-web-auto`, but the host directory is
> `hosts/nixos-calibre-wa`.

## Proxmox configuration

### FUSE passthrough

`rclone mount` inside the LXC needs `/dev/fuse` from the host. Add to the
container conf (`/etc/pve/lxc/<id>.conf`) on Proxmox:

```
lxc.cgroup2.devices.allow: c 10:229 rwm
lxc.mount.entry: /dev/fuse dev/fuse none bind,create=file 0 0
```

`c 10:229` = misc major 10, minor 229 = `/dev/fuse`. After adding, restart
the LXC. Without these lines, `rclone mount` fails with "Permission denied".

## Exposed ports

| Service | Port |
|---|---|
| Calibre-Web-Automated (UI) | 8083 |

## First boot

1. Import the tarball as template in Proxmox; add the FUSE lines above; create
   the LXC. Resource suggestion: 1–2 CPU, 2–4 GB RAM, 10–20 GB disk.
2. Start the container. `systemctl status rclone-pcloud.service` should show
   the pCloud mount at `/mnt/pcloud` as `Type=notify` with `Restart=on-failure`.
3. Confirm the mount: `ls /mnt/pcloud` should list the library.
4. Confirm CWA: `systemctl status podman-calibre-web-automated.service`
   (starts `after` + `requires` rclone).
5. Open `http://<IP>:8083` in a browser.

### pCloud token provisioning

The rclone config lives in a sops-encrypted `secrets/calibre-wa.yaml`. The
`token =` field inside it is the pCloud OAuth2 token. To refresh:

```bash
rclone authorize "pcloud"   # on a machine with a browser
# paste the returned token into the sops file, re-encrypt, re-apply
```

## SSH

```bash
ssh nixos-calibre-web-auto@<IP>
```

## Apply changes

Remote:

```bash
nixos-rebuild switch --flake .#nixos-calibre-web-auto --target-host <user>@<ip> --elevate=sudo
```

Inside the container:

```bash
sudo nixos-rebuild switch --flake .#nixos-calibre-web-auto
```
