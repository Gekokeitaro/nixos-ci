{
  pkgs,
  isLlamacppRocm ? false,
  hostName,
  ...
}: let
  lib = pkgs.lib;

  llamaCpp = import ./packages/llama-cpp {inherit pkgs isLlamacppRocm;};
  llama-server = "${llamaCpp}/bin/llama-server";

  # 1-June-26. FIX: Parece que DeviceLost ocurre porque entre llamadas a intercambios de modelos no hay tiempo
  # suficiente para que se limpie el estado de la gpu. El wrapper añade 2s. que está testeado y funciona.
  llama-server-delayed = pkgs.writeShellScript "llama-server-delayed" ''
    sleep 2
    exec ${llama-server} "$@"
  '';
in {
  imports = [
    ../../common
  ];

  users.users.${hostName} = {
    isNormalUser = true;

    extraGroups = ["wheel" "render" "video"];

    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGApUnvphJshC3LJ4QxDu8fm3JqEnSWZ6ewhf6gQuF7V PopOS OCT 2024"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFeASXjLf7TjNTxO5CZ4Aa6z8hyFG0CXAe4FhcpZOEp6 NixOS-CI MAY 2026"
    ];

    packages = with pkgs; [
      tree
      git
      curl
      wget
      magic-wormhole
      vulkan-tools
      radeontop
    ];
  };

  services.llama-swap = {
    enable = true;
    listenAddress = "0.0.0.0";
    port = 8080;
    openFirewall = true; # Añade port a allowedTCPPorts. Necesario con Proxmox?
    settings = {
      models = lib.mkMerge [
        (import ./models/Bartowski-Ling-3.0-tiny-Q8_0.nix {llama-server = llama-server-delayed;})
        (import ./models/ISTA-DASlab-Qwen3.8-27B-GSQ-RCO-IQ3_XXS-mtp.nix {llama-server = llama-server-delayed;})
        (import ./models/InternScience-Agents-A1-4B-Q8_0.nix {llama-server = llama-server-delayed;})
        (import ./models/InternScience-Agents-A1-4B-Q4_K_M.nix {llama-server = llama-server-delayed;})
        (import ./models/Tesslate-omnicoder-9b-q4_k_m-w-dflash.nix {llama-server = llama-server-delayed;})
        (import ./models/Unsloth-DeepSeek-R1-Distill-Qwen-14B-Q4_K_M.nix {llama-server = llama-server-delayed;})
        (import ./models/Unsloth-Devstral-Small-2-24B-Instruct-2512-UD-Q4_K_XL.nix {llama-server = llama-server-delayed;})
        (import ./models/Unsloth-GLM-4.7-Flash-REAP-23B-A3B-UD-Q4_K_XL.nix {llama-server = llama-server-delayed;})
        (import ./models/Unsloth-Qwen3.5-9B-UD-Q4_K_XL.nix {llama-server = llama-server-delayed;})
        (import ./models/Unsloth-Qwen3.6-35B-A3B-UD-IQ3_XXS.nix {llama-server = llama-server-delayed;})
        (import ./models/Unsloth-gemma-4-E4B-it-qat-UD-Q4_K_XL.nix {llama-server = llama-server-delayed;})
        (import ./models/Unsloth-gemma-4-12B-it-qat-UD-Q4_K_XL.nix {llama-server = llama-server-delayed;})
        (import ./models/Unsloth-gpt-oss-20b-Q4_K_M.nix {llama-server = llama-server-delayed;})
        (import ./models/XHToken-Spark-X2.5-4B-Q8_0.nix {llama-server = llama-server-delayed;})
      ];
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

  environment.variables = lib.mkMerge [
    # Común a ambos perfiles: limita el tamaño de las submissions Vulkan/ROCm.
    {
      GGML_VK_MAX_NODES_PER_SUBMIT = 1;
      GGML_CUDA_ENABLE_UNIFIED_MEMORY = 1;
    }
    (lib.optionalAttrs isLlamacppRocm {
      # gfx1035 no está en la lista oficial de ROCm; forzamos compatibilidad.
      HSA_OVERRIDE_GFX_VERSION = "10.3.0";
    })
    (lib.optionalAttrs (!isLlamacppRocm) {
      # RADV tiene mejor soporte RDNA2 que amdvlk.
      AMD_VULKAN_ICD = "RADV";
    })
  ];

  nix.settings.trusted-users = ["nixos-llamaswap-vulkan"];

  nix.settings.experimental-features = ["nix-command" "flakes"];

  system.stateVersion = "26.05";
}
