{pkgs, ...}: let
  domain = "192.168.18.31";
  port = 3000;
in {
  imports = [
    ../../common
  ];

  networking.hostName = "nixos-forgejo";

  users.users.nixos-forgejo = {
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

  services.forgejo = {
    enable = true;
    database.type = "sqlite3";

    settings = {
      # false → el registro está abierto; cualquiera puede crear cuenta.
      # Poner a true una vez creado el admin para cerrar el registro público.
      service.DISABLE_REGISTRATION = true;

      server = {
        HTTP_PORT = port;
        DOMAIN = domain;
        ROOT_URL = "http://${domain}:${toString port}/";
      };
    };
  };

  networking.firewall.allowedTCPPorts = [port];

  nix.settings.experimental-features = ["nix-command" "flakes"];

  system.stateVersion = "26.05";
}
