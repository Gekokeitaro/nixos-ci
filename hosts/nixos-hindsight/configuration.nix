{
  pkgs,
  config,
  ...
}: {
  imports = [
    ../../common
  ];

  sops = {
    age.keyFile = "/home/nixos-hindsight/.config/sops/age/keys.txt";
    secrets.hindsight-env = {
      sopsFile = ./secrets/hindsight-env.env;
      format = "dotenv";
      mode = "0444";
    };
  };

  networking.hostName = "nixos-hindsight";

  users.users.nixos-hindsight = {
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

  virtualisation.oci-containers.containers.hindsight = {
    image = "ghcr.io/vectorize-io/hindsight:latest";

    environment = {
      HINDSIGHT_API_LLM_PROVIDER = "openai";
      HINDSIGHT_API_LLM_BASE_URL = "http://192.168.18.32:20128/v1";
      HINDSIGHT_API_LLM_MODEL = "static-best-free";
    };

    environmentFiles = [config.sops.secrets.hindsight-env.path];

    ports = ["8888:8888" "9999:9999"];
  };

  networking.firewall.allowedTCPPorts = [8888 9999];

  nix.settings.trusted-users = ["nixos-hindsight"];

  nix.settings.experimental-features = ["nix-command" "flakes"];

  system.stateVersion = "26.05";
}
