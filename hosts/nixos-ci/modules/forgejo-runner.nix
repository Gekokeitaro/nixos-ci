
{
  pkgs,
  config,
  ...
}: {
  systemd.services.forgejo-runner-ci = {
    # `path` reemplaza el PATH por defecto del servicio: lo que no esté aquí no
    # existe para los pasos del workflow, aunque el host lo tenga en el perfil del
    # sistema. `nix` hace falta para `nix run` (update-llama-bench-runner).
    path = with pkgs; [
      nix
      nixos-rebuild
      openssh
    ];

    serviceConfig.LoadCredential = [
      "deploykey:${config.sops.secrets.deploy-key.path}"
    ];
  };

  services.forgejo-runner.instances.ci = {
    enable = true;
    settings = {
      server.connections.forgejo = {
        url = "http://192.168.18.31:3000";
        uuid = "15ab8222-2f49-49a6-8969-828b64614dc3";
      };
      runner.labels = ["host:host"];
    };
    secrets.server.connections.forgejo.token_url =
      config.sops.secrets.forgejo-runner-token.path;
  };

  sops.secrets.forgejo-runner-token.sopsFile = ../secrets.yaml;

  sops.secrets.deploy-key = {
    sopsFile = ../secrets.yaml;
    mode = "0400";
  };
}
