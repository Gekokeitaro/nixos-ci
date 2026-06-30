{ config, pkgs, ... }:
{
  imports = [
    ../../common
  ];

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
      magic-wormhole
    ];

    #virtualization.podman = {
    #  enable = true;
    #  defaultNetwork.settings.dns_enabled = true;
    #};
#
    #virtualisation.oci-containers.containers = {
    #  calibre-web-automated = {
    #    image = "crocodilestick/calibre-web-automated:latest";
    #    environment = {
    #      PUID = "1000";
    #      PGID = "1000";
    #      TZ = "Europe/Madrid";
    #    };
    #    volumes = [
    #      "/path/to/config/folder:/config"
    #      "/path/to/the/folder/you/want/to/use/for/book/ingest:/cwa-book-ingest"
    #      "/path/to/your/calibre/library:/calibre-library"
    #      "/path/to/your/calibre/plugins/folder:/config/.config/calibre/plugins"
    #    ];
    #    ports = [
    #      "8083:8083"
    #    ];
    #  };
    #}
  };

  nix.settings.experimental-features = ["nix-command" "flakes"];

  system.stateVersion = "26.05";
}