{
  pkgs,
  config,
  ...
}: {
  imports = [
    ../../common
  ];

  sops = {
    defaultSopsFile = ./secrets.yaml;
    defaultSopsFormat = "yaml";
    age.keyFile = "/home/nixos-n8n/.config/sops/age/keys.txt";
    secrets.n8n_db_password = {
      sopsFile = ../../common/secrets/postgresql-shared.yaml;
      mode = "0444";
    };
    secrets.n8n_runner_auth_token = {
      mode = "0444";
    };
  };

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

  virtualisation.oci-containers.containers.n8n = {
    image = "docker.io/n8nio/n8n:stable";

    environment = {
      GENERIC_TIMEZONE = "Europe/Madrid";
      TZ = "Europe/Madrid";
      N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS = "true";
      N8N_SECURE_COOKIE = "false";

      DB_TYPE = "postgresdb";
      DB_POSTGRESDB_HOST = "192.168.18.60";
      DB_POSTGRESDB_PORT = "5432";
      DB_POSTGRESDB_USER = "n8n";
      DB_POSTGRESDB_PASSWORD_FILE = config.sops.secrets.n8n_db_password.path;

      N8N_RUNNERS_MODE = "external";
      N8N_RUNNERS_BROKER_LISTEN_ADDRESS = "0.0.0.0";
      N8N_RUNNERS_AUTH_TOKEN_FILE = config.sops.secrets.n8n_runner_auth_token.path;
    };

    volumes = [
      "n8n_data:/home/node/.n8n"
      "${config.sops.secrets.n8n_db_password.path}:/run/secrets/n8n_db_password"
      "${config.sops.secrets.n8n_runner_auth_token.path}:/run/secrets/n8n_runner_auth_token"
    ];

    ports = ["5678:5678" "5679:5679"];
  };

  networking.firewall.allowedTCPPorts = [5678 5679];

  nix.settings.trusted-users = ["nixos-n8n"];

  nix.settings.experimental-features = ["nix-command" "flakes"];

  system.stateVersion = "26.05";
}
