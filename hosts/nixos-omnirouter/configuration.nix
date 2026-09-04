{
  pkgs,
  lib,
  ...
}: let
  omniroute = import ../packages/omniroute {inherit pkgs;};
in {
  imports = [../../common];

  users.users.nixos-omnirouter = {
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
      magic-wormhole
    ];
  };

  systemd.services.omniroute = {
    enable = true;
    description = "OmniRoute AI Gateway";
    wantedBy = ["multi-user.target"];
    after = ["network.target"];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${omniroute}/bin/omniroute";
      Restart = "on-failure";
    };
  };

  networking.firewall.allowedTCPPorts = [20128];

  nix.settings.experimental-features = ["nix-command" "flakes"];

  system.stateVersion = "26.05";
}
