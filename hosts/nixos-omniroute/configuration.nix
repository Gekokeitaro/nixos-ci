{
  pkgs,
  config,
  ...
}: {
  imports = [../../common];

  sops = {
    defaultSopsFile = ../../common/secrets.yaml;
    age.keyFile = "/var/lib/sops-nix/key.yaml";
    secrets."ssh_authorized_keys/nixos-ci" = {};
  };

  users.users.nixos-omniroute = {
    isNormalUser = true;
    extraGroups = ["wheel"];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGApUnvphJshC3LJ4QxDu8fm3JqEnSWZ6ewhf6gQuF7V PopOS OCT 2024"
      config.sops.secrets."ssh_authorized_keys/nixos-ci".path
    ];
    packages = with pkgs; [
      tree
      git
      curl
      wget
      magic-wormhole
      jq
    ];
  };

  systemd.tmpfiles.rules = ["d /var/lib/omniroute 0750 1000 1000 -"];

  virtualisation.oci-containers.containers = {
    omniroute = {
      image = "docker.io/diegosouzapw/omniroute:latest";

      environment = {
        # PUID/PGID deben coincidir con dueño de los volúmenes en host,
        # si no: errores de permisos.
        PUID = "1000";
        PGID = "1000";
        TZ = "Europe/Madrid";
        OMNIROUTE_BOOTSTRAPPED = "true";
      };

      volumes = ["/var/lib/omniroute:/app/data"];

      ports = [
        "20128:20128"
      ];
    };
  };

  nix.settings.trusted-users = ["nixos-omniroute"];

  nix.settings.experimental-features = ["nix-command" "flakes"];

  system.stateVersion = "26.05";
}
