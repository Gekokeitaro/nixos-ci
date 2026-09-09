{
  pkgs,
  config,
  ...
}: {
  imports = [
    ../../common
  ];

  users.users.nixos-postgresql = {
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
      bat
      magic-wormhole
    ];
  };

  services.postgresql = {
    enable = true;
    enableTCPIP = true;
  };

  networking.firewall.allowedTCPPorts = [5432];

  nix.settings.trusted-users = ["nixos-postgresql"];

  nix.settings.experimental-features = ["nix-command" "flakes"];

  system.stateVersion = "26.05";
}
