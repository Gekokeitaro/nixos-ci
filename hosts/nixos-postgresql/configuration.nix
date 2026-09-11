{
  pkgs,
  config,
  ...
}: {
  imports = [
    ../../common
  ];

  sops = {
    age.keyFile = "/home/nixos-postgresql/.config/sops/age/keys.txt";
    secrets.n8n_db_password = {
      sopsFile = ../../common/secrets/postgresql-shared.yaml;
      mode = "0444";
    };
    secrets.hindsight_db_password = {
      sopsFile = ../../common/secrets/postgresql-shared.yaml;
      mode = "0444";
    };
  };

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

    ensureDatabases = ["n8n" "hindsight"];
    ensureUsers = [
      {
        name = "n8n";
        ensureDBOwnership = true;
      }
      {
        name = "hindsight";
        ensureDBOwnership = true;
      }
    ];

    authentication = pkgs.lib.mkOverride 10 ''
      #type database DBuser origin-address auth-method
      local all      all    trust
      host  n8n      n8n    192.168.18.22/24 scram-sha-256
      host  hindsight hindsight 192.168.18.19/24 scram-sha-256

    '';

    extensions = posgresPackages: with posgresPackages; [pgvector];
  };

  systemd.services.one-shot-config = {
    description = "Fija la contraseña del rol n8n desde el secreto de sops";
    after = ["postgresql.service"];
    wants = ["postgresql.service"];
    wantedBy = ["multi-user.target"];
    serviceConfig.Type = "oneshot";
    serviceConfig.User = "postgres";
    script = ''
      PASS_N8N=$(cat ${config.sops.secrets.n8n_db_password.path})
      PASS_HS=$(cat ${config.sops.secrets.hindsight_db_password.path})
      ${config.services.postgresql.package}/bin/psql -U postgres <<SQL
      ALTER ROLE n8n WITH PASSWORD '$PASS_N8N';
      ALTER ROLE hindsight WITH PASSWORD '$PASS_HS';
      SQL
      ${config.services.postgresql.package}/bin/psql -d hindsight -c "CREATE EXTENSION IF NOT EXISTS vector;"
    '';
  };
  networking.firewall.allowedTCPPorts = [5432];

  nix.settings.trusted-users = ["nixos-postgresql"];

  nix.settings.experimental-features = ["nix-command" "flakes"];

  system.stateVersion = "26.05";
}
