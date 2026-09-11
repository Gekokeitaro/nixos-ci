{
  pkgs,
  config,
  ...
}: {
  imports = [../../common];

  sops = {
    defaultSopsFormat = "yaml";
    age.keyFile = "/home/nixos-n8n-runner/.config/sops/age/keys.txt";
    secrets.n8n_runner_auth_token = {
      sopsFile = ./secrets/auth-env.yaml;
      mode = "0444";
    };
  };

  users.users.nixos-n8n-runner = {
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
      jq
    ];
  };

  virtualisation.oci-containers.containers.n8n-task-runners = {
    image = "docker.io/n8nio/runners:stable";

    environment = {
      N8N_RUNNERS_TASK_BROKER_URI = "http://192.168.18.22:5678";
      N8N_RUNNERS_AUTO_SHUTDOWN_TIMEOUT = "15";
    };

    environmentFiles = [config.sops.secrets.n8n_runner_auth_token.path];

    ports = [
      "20128:20128"
    ];
  };

  nix.settings.trusted-users = ["nixos-n8n-runner"];

  nix.settings.experimental-features = ["nix-command" "flakes"];

  system.stateVersion = "26.05";
}
