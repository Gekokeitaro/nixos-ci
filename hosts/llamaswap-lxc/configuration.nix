{
  pkgs,
  isLlamacppRocm ? false,
  ...
}: {
  imports = [
    ../../common
    ../../packages/llama-cpp
    {inherit isLlamacppRocm;}
  ];

  users.users.nixos-llamaswap-vulkan = {
    isNormalUser = true;

    extraGroups = ["wheel" "render" "video"];

    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGApUnvphJshC3LJ4QxDu8fm3JqEnSWZ6ewhf6gQuF7V PopOS OCT 2024"
    ];

    packages = with pkgs; [
      tree
      git
      curl
      wget
      magic-wormhole
      (import ./llama-cpp {
        inherit
          isLlamacppRocm
          pkgs
          ;
      })
    ];
  };

  services.llama-swap = {
    enable = true;
    listenAddress = "0.0.0.0";
    port = 8080;
    # openFirewall = true; # Añade port a allowedTCPPorts. Necesario con Proxmox?
    settings = {};
  };

  nix.settings.experimental-features = ["nix-command" "flakes"];

  system.stateVersion = "26.05";
}
