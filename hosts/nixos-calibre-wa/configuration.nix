# calibre-lxc: serves Calibre-Web-Automated (CWA).
# CWA = Calibre-Web web UI + Calibre engine + auto-ingest, all in one.
# Repo: https://github.com/crocodilestick/Calibre-Web-Automated
#
# Library lives on pCloud, mounted locally via rclone+FUSE; the container
# sees it as a normal directory.
#
# Boot order (fixed, see systemd.services below):
#   tmpfiles creates /mnt/pcloud + rclone.conf symlink
#   → rclone-pcloud.service mounts pcloud: (Type=notify, signals when ready)
#   → podman-calibre-web-automated starts (after+requires rclone, otherwise
#     Podman could statfs /mnt/pcloud before the mount)
#   → UI on port 8083.
#
# Requirement outside Nix, Proxmox host, in /etc/pve/lxc/<id>.conf
# (unprivileged LXC, FUSE needs this by hand):
#   lxc.cgroup2.devices.allow: c 10:229 rwm
#   lxc.mount.entry: /dev/fuse dev/fuse none bind,create=file 0 0
{
  config,
  pkgs,
  ...
}: let
  # rclone config in the Nix store. pCloud OAuth2 token below (empty here,
  # unversioned secret). Renew: `rclone authorize "pcloud"` on a machine
  # with a browser, paste the token into `token =`.
  # hostname = eapi.pcloud.com → EU pCloud endpoint.
in {
  imports = [
    ../../common
  ];

  sops = {
    age.keyFile = "/home/nixos-calibre-web-auto/.config/sops/age/keys.txt";
    secrets.rclone-pcloud-conf = {
      sopsFile = ./secrets/calibre-wa.yaml;
      mode = "0444";
    };
  };

  # Service user: SSH + rclone mount (interactive shell) + maintenance
  # CLI. The rclone systemd service runs as root because it
  # uses --allow-other (requires privileges; see programs.fuse below).
  users.users.nixos-calibre-web-auto = {
    isNormalUser = true;
    extraGroups = ["wheel"]; # sudo for maintenance

    # SSH key for remote access
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGApUnvphJshC3LJ4QxDu8fm3JqEnSWZ6ewhf6gQuF7V PopOS OCT 2024"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFeASXjLf7TjNTxO5CZ4Aa6z8hyFG0CXAe4FhcpZOEp6 NixOS-CI MAY 2026"
    ];

    packages = with pkgs; [
      tree
      git
      curl
      wget
      magic-wormhole # fast file transfer between machines
      rclone
      fuse3
    ];
  };

  virtualisation.oci-containers.containers.calibre-web-automated = {
    image = "docker.io/crocodilestick/calibre-web-automated:latest";

    environment = {
      # PUID/PGID must match the owner of the volumes on the host,
      # otherwise: permission errors.
      PUID = "1000";
      PGID = "1000";
      TZ = "Europe/Madrid";
    };

    volumes = [
      "/home/nixos-calibre-web-auto/.config/calibre-web-automated/config:/config"
      "/home/nixos-calibre-web-auto/.config/calibre-web-automated/plugins:/config/.config/calibre/plugins"
      "/mnt/pcloud:/calibre-library" # pCloud library mounted by rclone
    ];

    ports = [
      "8083:8083" # UI: http://<ip-lxc>:8083
    ];
  };

  # Without this explicit dependency, systemd could start both services
  # in parallel and Podman would fail the statfs of /mnt/pcloud.
  systemd.services.podman-calibre-web-automated = {
    after = ["rclone-pcloud.service"];
    requires = ["rclone-pcloud.service"];
  };

  # Allow non-root processes (the OCI container) to access the FUSE mount
  # with --allow-other. Equivalent to user_allow_other in /etc/fuse.conf.
  programs.fuse.userAllowOther = true;

  systemd.tmpfiles.rules = [
    "d /mnt/pcloud 0755 root root -"
    "d /home/nixos-calibre-web-auto/.config/calibre-web-automated/config 0755 nixos-calibre-web-auto users -"
    "d /home/nixos-calibre-web-auto/.config/calibre-web-automated/plugins 0755 nixos-calibre-web-auto users -"
  ];

  # Mount pCloud at /mnt/pcloud.
  #   --vfs-cache-mode writes → writes go to the local cache, then sync;
  #     reads go straight to the remote (streaming).
  #   --allow-other → required for the OCI container to access the mount.
  #   Type=notify → rclone tells systemd when the mount is ready,
  #     so podman-calibre-web-automated does not start too early.
  systemd.services.rclone-pcloud = {
    description = "rclone mount of pCloud";
    after = ["network-online.target"];
    wants = ["network-online.target"];
    wantedBy = ["multi-user.target"];

    serviceConfig = {
      Type = "notify";
      ExecStart = ''
        ${pkgs.rclone}/bin/rclone mount \
        pcloud: \
        /mnt/pcloud \
        --config ${config.sops.secrets.rclone-pcloud-conf.path} \
        --vfs-cache-mode writes \
        --allow-other
      '';
      ExecStop = "${pkgs.fuse3}/bin/fusermount3 -u /mnt/pcloud"; # clean unmount
      Restart = "on-failure"; # rclone dies (e.g. network) → restart
      RestartSec = "5s";
    };
  };

  nix.settings.trusted-users = ["nixos-calibre-web-auto"];

  nix.settings.experimental-features = ["nix-command" "flakes"]; # required for nixos-rebuild --flake inside the LXC

  system.stateVersion = "26.05";
}
