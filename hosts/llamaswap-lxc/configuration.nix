{
  pkgs,
  isLlamacppRocm ? false,
  ...
}: let
  lib = pkgs.lib;

  llamaCpp = import ../../packages/llama-cpp {inherit pkgs isLlamacppRocm;};
  llama-server = "${llamaCpp}/bin/llama-server";

  # 1-June-26. FIX: Parece que DeviceLost ocurre porque entre llamadas a intercambios de modelos no hay tiempo
  # suficiente para que se limpie el estado de la gpu. El wrapper añade 2s. que está testeado y funciona.
  llama-server-delay = 2;
  llama-server-delayed = pkgs.writeShellScript "llama-server-delayed" ''
    sleep 2
    exec ${llama-server} "$@"
  '';
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
        (import ./models/qwen3-embedding-0.6B_Q8_0.nix {llama-server = llama-server-delayed;})
        (import ./models/gemma-4-E4B-it-UD-Q4_K_XL.nix {llama-server = llama-server-delayed;})
        (import ./models/bge-reranker-v2-m3-q8_0.nix {llama-server = llama-server-delayed;})
        (import ./models/gpt-oss-20b-Q4_K_M.nix {llama-server = llama-server-delayed;})
        (import ./models/Gemma-4-19B.i1-Q4_K_M.nix {llama-server = llama-server-delayed;})
        (import ./models/Mellum2-12B-A2.5B-Instruct-Q4_K_M.nix {llama-server = llama-server-delayed;})
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

  systemd.services.llama-swap = {
    environment = {
      MESA_SHADER_CACHE_DIR = "/var/cache/llama-swap";
      XDG_CACHE_HOME = "/var/cache/llama-swap";
    };
    serviceConfig = {
      CacheDirectory = "llama-swap";
    };
  };

  # Drivers GPU de runtime según el perfil elegido.
  # La compilación de llama-cpp ya los incluye como buildInputs via .override.
  hardware.graphics.extraPackages = with pkgs;
    if isLlamacppRocm
    then [
      rocmPackages.clr
      rocmPackages.clr.icd
    ]
    else [
      vulkan-loader
    ];

  environment.variables =
    if isLlamacppRocm
    then {
      # gfx1035 no está en la lista oficial de ROCm; forzamos compatibilidad.
      HSA_OVERRIDE_GFX_VERSION = "10.3.0";
    }
    else {
      # RADV tiene mejor soporte RDNA2 que amdvlk.
      AMD_VULKAN_ICD = "RADV";
    };

  nix.settings.experimental-features = ["nix-command" "flakes"];

  system.stateVersion = "26.05";
}
