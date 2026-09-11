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
    age.keyFile = "/home/nixos-ci/.config/sops/age/keys.txt";
    secrets.forgejo-runner-token = {};
  };

  users.users.nixos-ci = {
    isNormalUser = true;

    extraGroups = ["wheel"];

    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGApUnvphJshC3LJ4QxDu8fm3JqEnSWZ6ewhf6gQuF7V PopOS OCT 2024"
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

  virtualisation.podman.enable = true;
  services.forgejo-runner.instances.nixos-runner = {
    enable = true;
    settings.runner.labels = ["docker"];
    settings.server.connections.nixos-forgejo = {
      url = "http://192.168.18.31:3000/";
      uuid = "48ffc057-ff70-4b49-a19d-2848045fa023";
    };
    secrets = {
      server.connections.nixos-forgejo = {
        token_url = config.sops.secrets.forgejo-runner-token.path;
      };
    };
    runtimes.podman = true;
  };

  nix.settings.experimental-features = ["nix-command" "flakes"];

  system.stateVersion = "26.05";
}
