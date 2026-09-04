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
    ];
    packages = with pkgs; [
      tree
      git
      curl
      wget
      magic-wormhole
    ];
  };

  virtualisation.podman = {
    enable = true;
    defaultNetwork.settings.dns_enabled = true;
  };

  virtualisation.oci-containers.containers.omniroute = {
    image = "diegosouzapw/omniroute:latest";

    environment = {
      # OMNIROUTE_MEMORY_MB = "1024";
      # OMNIROUTE_WS_BRIDGE_SECRET = "<generar>";
      # INITIAL_PASSWORD = "<generar>";
      # TZ = "Europe/Madrid";
    };

    volumes = [
      "omniroute-data:/app/data"
    ];

    ports = [
      "20128:20128"
    ];
  };

  networking.firewall.allowedTCPPorts = [20128];

  nix.settings.experimental-features = ["nix-command" "flakes"];

  system.stateVersion = "26.05";
}
