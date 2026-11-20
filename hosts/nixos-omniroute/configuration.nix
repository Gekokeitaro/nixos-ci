{
  pkgs,
  config,
  ...
}: {
  imports = [../../common];

  users.users.nixos-omniroute = {
    isNormalUser = true;
    extraGroups = ["wheel"];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGApUnvphJshC3LJ4QxDu8fm3JqEnSWZ6ewhf6gQuF7V PopOS OCT 2024"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFeASXjLf7TjNTxO5CZ4Aa6z8hyFG0CXAe4FhcpZOEp6 NixOS-CI MAY 2026"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOItHReLpLr0DZHohVHBdqu7CePpsuQ3ANa0UsUX0xj+ pablo.bugarin.camara@gmail.com"
      # The Forgejo runner's deploy key, the same one the model host carries: it is what
      # `.forgejo/workflows/deploy-omniroute.yml` authenticates with. It only works once
      # this configuration has been applied to the host **once by hand** — a key cannot
      # deploy itself.
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG1kMUYO4VHcsypjXFxKcmdzki6/L0dcIW2BW2eopotS deploy-runner"
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
        # PUID/PGID must match the owner of the volumes on the host,
        # otherwise: permission errors.
        PUID = "1000";
        PGID = "1000";
        TZ = "Europe/Madrid";
        OMNIROUTE_BOOTSTRAPPED = "true";
        STREAM_READINESS_TIMEOUT_MS = "300000";
        STREAM_READINESS_MAX_TIMEOUT_MS = "600000";
        STREAM_IDLE_TIMEOUT_MS = "600000";
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
