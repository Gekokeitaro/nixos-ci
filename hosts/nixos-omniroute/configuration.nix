{
  pkgs,
  lib,
  ...
}: {
  imports = [../../common];

  users.users.nixos-omniroute = {
    isNormalUser = true;
    extraGroups = ["wheel"];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGApUnvphJshC3LJ4QxDu8fm3JqEnSWZ6ewhf6gQuF7V PopOS OCT 2024"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFeASXjLf7TjNTxO5CZ4Aa6z8hyFG0CXAe4FhcpZOEp6 NixOS-CI MAY 2026"
    ];
    packages = with pkgs; [
      tree
      git
      curl
      wget
      magic-wormhole
    ];
  };

  virtualisation.oci-containers.containers = {
    omniroute = {
      image = "docker.io/diegosouzapw/omniroute:latest";

      environment = {
        # PUID/PGID deben coincidir con dueño de los volúmenes en host,
        # si no: errores de permisos.
        PUID = "1000";
        PGID = "1000";
        TZ = "Europe/Madrid";
      };

      ports = [
        "20128:20128"
      ];
    };
  };

  nix.settings.allowed-users = ["nixos-omniroute"];

  nix.settings.experimental-features = ["nix-command" "flakes"];

  system.stateVersion = "26.05";
}
