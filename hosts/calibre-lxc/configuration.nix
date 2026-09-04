# calibre-lxc: sirve Calibre-Web-Automated (CWA).
# CWA = UI web de Calibre-Web + motor Calibre + auto-ingest, en uno.
# Repo: https://github.com/crocodilestick/Calibre-Web-Automated
#
# Librería vive en pCloud, montada local vía rclone+FUSE; el contenedor
# la ve como directorio normal.
#
# Orden de arranque (fijo, ver systemd.services abajo):
#   tmpfiles crea /mnt/pcloud + symlink rclone.conf
#   → rclone-pcloud.service monta pcloud: (Type=notify, avisa cuando listo)
#   → podman-calibre-web-automated arranca (after+requires rclone, si no
#     Podman podría statfs /mnt/pcloud antes del mount)
#   → UI en puerto 8083.
#
# Requisito fuera de Nix, host Proxmox, en /etc/pve/lxc/<id>.conf
# (LXC no-privilegiado, FUSE necesita esto a mano):
#   lxc.cgroup2.devices.allow: c 10:229 rwm
#   lxc.mount.entry: /dev/fuse dev/fuse none bind,create=file 0 0
{
  config,
  pkgs,
  ...
}: let
  # Config rclone en el Nix store. Token OAuth2 de pCloud abajo (vacío aquí,
  # secreto no versionado). Renovar: `rclone authorize "pcloud"` en máquina
  # con navegador, pegar token en `token =`.
  # hostname = eapi.pcloud.com → endpoint EU de pCloud.
  rcloneConfig = pkgs.writeText "rclone.conf" ''
    [pcloud]
    type = pcloud
    hostname = eapi.pcloud.com
    token = 
  '';
in {
  imports = [
    ../../common
  ];

  # Usuario de servicio: SSH + montaje rclone (shell interactivo) + CLI
  # de mantenimiento. El servicio systemd de rclone corre como root porque
  # usa --allow-other (requiere privilegios; ver programs.fuse abajo).
  users.users.nixos-calibre-web-auto = {
    isNormalUser = true;
    extraGroups = ["wheel"]; # sudo para mantenimiento

    # Clave SSH para conexión remota
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGApUnvphJshC3LJ4QxDu8fm3JqEnSWZ6ewhf6gQuF7V PopOS OCT 2024"
    ];

    packages = with pkgs; [
      tree
      git
      curl
      wget
      magic-wormhole # transferencia rápida de ficheros entre máquinas
      rclone
      fuse3
    ];
  };

  virtualisation.podman = {
    enable = true;
    defaultNetwork.settings.dns_enabled = true; # DNS interno entre servicios
  };

  virtualisation.oci-containers.containers = {
    calibre-web-automated = {
      image = "crocodilestick/calibre-web-automated:latest";

      environment = {
        # PUID/PGID deben coincidir con dueño de los volúmenes en host,
        # si no: errores de permisos.
        PUID = "1000";
        PGID = "1000";
        TZ = "Europe/Madrid";
      };

      volumes = [
        "/home/nixos-calibre-web-auto/.config/calibre-web-automated/config:/config"
        "/home/nixos-calibre-web-auto/.config/calibre-web-automated/plugins:/config/.config/calibre/plugins"
        "/mnt/pcloud:/calibre-library" # librería pCloud montada por rclone
      ];

      ports = [
        "8083:8083" # UI: http://<ip-lxc>:8083
      ];
    };
  };

  # Sin esta dependencia explícita, systemd podría arrancar ambos servicios
  # en paralelo y Podman fallaría el statfs de /mnt/pcloud.
  systemd.services.podman-calibre-web-automated = {
    after = ["rclone-pcloud.service"];
    requires = ["rclone-pcloud.service"];
  };

  # Permite a procesos no-root (el contenedor OCI) acceder al mount FUSE
  # con --allow-other. Equivale a user_allow_other en /etc/fuse.conf.
  programs.fuse.userAllowOther = true;

  systemd.tmpfiles.rules = [
    "d /mnt/pcloud 0755 root root -"
    "d /home/nixos-calibre-web-auto/.config/calibre-web-automated/config 0755 root root -"
    "d /home/nixos-calibre-web-auto/.config/calibre-web-automated/plugins 0755 root root -"
    "d /home/nixos-calibre-web-auto/.config/rclone 0700 nixos-calibre-web-auto users -"
    # Symlink al rclone.conf del Nix store: config bajo control de Nix,
    # no hay que tocar ficheros a mano.
    "L /home/nixos-calibre-web-auto/.config/rclone/rclone.conf - nixos-calibre-web-auto users - ${rcloneConfig}"
  ];

  # Monta pCloud en /mnt/pcloud.
  #   --vfs-cache-mode writes → escrituras van a caché local, luego sync;
  #     lecturas van directas al remoto (streaming).
  #   --allow-other → necesario para que el contenedor OCI acceda al mount.
  #   Type=notify → rclone avisa a systemd cuando el mount está listo,
  #     así podman-calibre-web-automated no arranca antes de tiempo.
  systemd.services.rclone-pcloud = {
    description = "Montaje rclone de pCloud";
    after = ["network-online.target"];
    wants = ["network-online.target"];
    wantedBy = ["multi-user.target"];

    serviceConfig = {
      Type = "notify";
      ExecStart = "${pkgs.rclone}/bin/rclone mount pcloud: /mnt/pcloud --config ${rcloneConfig} --vfs-cache-mode writes --allow-other";
      ExecStop = "${pkgs.fuse3}/bin/fusermount3 -u /mnt/pcloud"; # desmonte limpio
      Restart = "on-failure"; # rclone muere (p.ej. red) → reinicia
      RestartSec = "5s";
    };
  };

  nix.settings.experimental-features = ["nix-command" "flakes"]; # necesario para nixos-rebuild --flake dentro del LXC

  system.stateVersion = "26.05";
}
