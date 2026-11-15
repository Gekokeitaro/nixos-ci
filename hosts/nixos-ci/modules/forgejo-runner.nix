
{
  pkgs,
  config,
  ...
}: {
  systemd.services.forgejo-runner-ci = {
    # `path` replaces the service's default PATH: whatever is missing here does
    # not exist for the workflow steps, even if the host has it in the system
    # profile. `nix` is required for `nix run` (update-llama-bench-runner).
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
