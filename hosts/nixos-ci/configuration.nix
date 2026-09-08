{
  pkgs,
  config,
  ...
}: {
  imports = [
    ../../common
  ];

  sops = {
    defaultSopsFile = ../../common/secrets.yaml;
    age.keyFile = "/var/lib/sops-nix/key.yaml";
    secrets."ssh_authorized_keys/nixos-ci" = {};
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

  nix.settings.experimental-features = ["nix-command" "flakes"];

  system.stateVersion = "26.05";
}
