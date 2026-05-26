{
  pkgs,
  isLlamacppRocm ? false,
  ...
}: let
  lib = pkgs.lib;

  llamaCpp = import ../../packages/llama-cpp {inherit pkgs isLlamacppRocm;};
  llama-server = "${llamaCpp}/bin/llama-server";
in {
  imports = [
    ../../common
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
    ];
  };

  services.llama-swap = {
    enable = true;
    listenAddress = "0.0.0.0";
    port = 8080;
    openFirewall = true; # Añade port a allowedTCPPorts. Necesario con Proxmox?
    settings = {
      models = lib.mkMerge [
        (import ./models/qwen3-embedding-0.6B_Q8_0.nix {inherit llama-server;})
        (import ./models/gemma-4-E4B-it-UD-Q4_K_XL.nix {inherit llama-server;})
        (import ./models/bge-reranker-v2-m3-q8_0.nix {inherit llama-server;})
      ];
      matrix = {
        vars = {
          embed = "Qwen3-Embedding-0.6B-Q8_0";
          reranker = "bge-reranker-v2-m3-q8_0";
          gemma = "gemma-4-E4B-it-UD-Q4_K_XL";
        };
        evict_costs = {
          embed = 99;
          reranker = 20;
          gemma = 50;
        };
        sets = {
          rag-process = "gemma & embed & reranker";
        };
      };
    };
  };

  nix.settings.experimental-features = ["nix-command" "flakes"];

  system.stateVersion = "26.05";
}
