{
  pkgs,
  config,
  ...
}: {
  imports = [
    ../../common
    ./modules/pi-coding-agent/default.nix
  ];

  piCodingAgent = {
    enable = true;
    modelsPath = ./config/models.json;
    settingsPath = ./config/settings.json;
    extensions = with pkgs; [];
  };

  users.users.nixos-pi-agent = {
    isNormalUser = true;

    extraGroups = ["wheel"];

    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGApUnvphJshC3LJ4QxDu8fm3JqEnSWZ6ewhf6gQuF7V PopOS OCT 2024"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFeASXjLf7TjNTxO5CZ4Aa6z8hyFG0CXAe4FhcpZOEp6 NixOS-CI MAY 2026"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJlIVU/DVCYrcuFm/DrU85FYrh1ZsDR0wc+AXsDwPreV nixos-n8n SEP 2026"
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

  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
  };

  nix.settings.trusted-users = ["nixos-pi-agent"];

  nix.settings.experimental-features = ["nix-command" "flakes"];

  system.stateVersion = "26.05";
}
