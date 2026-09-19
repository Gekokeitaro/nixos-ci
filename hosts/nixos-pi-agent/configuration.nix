{
  pkgs,
  config,
  ...
}: let
  user = "nixos-pi-agent";
  home = config.users.user.${user}.home;
  agentDir = "${home}/.pi/agent";
in {
  imports = [
    ../../common
  ];

  #sops = {
  #  defaultSopsFile = ./secrets.yaml;
  #  age.keyFile = "/home/nixos-ci/.config/sops/age/keys.txt";
  #  secrets.forgejo-runner-token = {};
  #};

  users.users.nixos-pi-agent = {
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
      pi-coding-agent
    ];
  };

  systemd.tmpfiles.rules = [
    "d ${home}/.pi 0755 ${user} users -"
    "d ${agentDir} 0755 ${user} users -"
    "d ${agentDir}/extensions 0755 ${user} users -"

    # Solo lectura (declarativo)
    "L+ ${agentDir}/models.json - - - - ${./config/models.json}"

    # Mutable: se copia solo si no existe
    "C ${agentDir}/settings.json 0644 ${user} users - ${./config/settings.json}"

    # Extensión propia, cargada por autodescubrimiento
    "L+ ${agentDir}/extensions/mi-ext.ts - - - - ${./pi/mi-ext.ts}"
  ];

  nix.settings.experimental-features = ["nix-command" "flakes"];

  system.stateVersion = "26.05";
}
