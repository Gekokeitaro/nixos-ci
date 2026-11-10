{config, ...}: {
  systemd.services.forgejo-runner-ci.path = with pkgs; [
    nixos-rebuild
    openssh
  ];

  services.forgejo-runner.instances.ci = {
    enable = true;
    settings = {
      server.connections.forgejo = {
        url = "http://192.168.18.31:3000";
        uuid = "15ab8222-2f49-49a6-8969-828b64614dc3"; # no es secreto, va en claro
      };
      runner.labels = ["host:host"]; # ejecuta directo en el LXC
    };
    secrets.server.connections.forgejo.token_url = config.sops.secrets.forgejo-runner-token.path;
  };

  sops.secrets.forgejo-runner-token.sopsFile = ../secrets.yaml;
  sops.secrets.deploy-key.sopsFile = ../secrets.yaml;
}
