{pkgs, ...}: {
  imports = [
    ../../common
  ];

  networking.hostName = "nixos-n8n";

  users.users.nixos-n8n = {
    isNormalUser = true;
    extraGroups = ["wheel"];

    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGApUnvphJshC3LJ4QxDu8fm3JqEnSWZ6ewhf6gQuF7V PopOS OCT 2024"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFeASXjLf7TjNTxO5CZ4Aa6z8hyFG0CXAe4FhcpZOEp6 NixOS-CI MAY 2026"
    ];
  };

  environment.systemPackages = with pkgs; [
    tree
    git
    curl
    wget
    magic-wormhole
  ];

  services.n8n = {
    enable = true;
    environment = {
      GENERIC_TIMEZONE = "Europe/Madrid";
      N8N_PORT = "5678";
      N8N_SECURE_COOKIE = "false";
    };

    openFirewall = true;
    taskRunners = {enable = true;};
  };

  nix.settings.trusted-users = ["nixos-n8n"];

  nix.settings.experimental-features = ["nix-command" "flakes"];

  system.stateVersion = "26.05";
}
