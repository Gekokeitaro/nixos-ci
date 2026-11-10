{config, ...}: {
  services.forgejo-runner.instances.ci = {
    enable = true;
    settings = {
      server.connections.forgejo = {
        url = "http://192.168.18.31:3000";
        uuid = "48ffc057-ff70-4b49-a19d-2848045fa023"; # no es secreto, va en claro
      };
      runner.labels = ["host:host"]; # ejecuta directo en el LXC
    };
    secrets.server.connections.forgejo.token_url = config.sops.secrets.forgejo-runner-token.path;
  };

  sops.secrets.forgejo-runner-token.sopsFile = ../secrets.yaml;
  sops.secrets.deploy-key.sopsFile = ../secrets.yaml;
}
