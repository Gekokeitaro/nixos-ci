{
  pkgs,
  isLlamacppRocm ? false,
  hostName,
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

  users.users.${hostName} = {
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
      vulkan-tools
      radeontop
      cowsay
    ];
  };

  services.llama-swap = {
    enable = true;
    listenAddress = "0.0.0.0";
    port = 8080;
    openFirewall = true; # Añade port a allowedTCPPorts. Necesario con Proxmox?
    settings = {
      models = lib.mkMerge [];
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

  virtualisation.oci-containers.containers = {
    omniroute = {
      image = "diegosouzapw/omniroute:latest";

      environment = {
        # PUID/PGID deben coincidir con dueño de los volúmenes en host,
        # si no: errores de permisos.
        PUID = "1000";
        PGID = "1000";
        TZ = "Europe/Madrid";
      };

      ports = [
        "20128:20128"
      ];
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

  nix.settings.experimental-features = ["nix-command" "flakes"];

  system.stateVersion = "26.05";
}
