{
  pkgs,
  isLlamacppRocm ? false,
  hostName,
  ...
}: let
  lib = pkgs.lib;

  gpuEnv =
    {
      # Shared: use main memory instead of failing when VRAM runs out.
      GGML_CUDA_ENABLE_UNIFIED_MEMORY = "1";
      # Shared: cap the size of Vulkan/ROCm submissions.
      GGML_VK_MAX_NODES_PER_SUBMIT = "1";
    }
    // lib.optionalAttrs isLlamacppRocm {
      # gfx1035 is not in the official ROCm list; force compatibility.
      # Remove if you move to the TheRock gfx103X-all binaries.
      HSA_OVERRIDE_GFX_VERSION = "10.3.0";
    }
    // lib.optionalAttrs (!isLlamacppRocm) {
      # RADV has better RDNA2 support than amdvlk.
      AMD_VULKAN_ICD = "RADV";
    };

  llamaCpp = import ./packages/llama-cpp {inherit pkgs isLlamacppRocm;};
  llama-server = "${llamaCpp}/bin/llama-server";

  # 1-June-26. FIX: DeviceLost seems to happen because between calls to model swaps there is not enough
  # time for the gpu state to be cleared. The wrapper adds 2s, which is tested and works.
  llama-server-delayed = pkgs.writeShellScript "llama-server-delayed" ''
    sleep 2
    exec ${llama-server} -lv 4 "$@"
  '';

  llamaBenchRunner = pkgs.fetchgit {
    url = "https://gitlab.com/Gekokeitaro/llama-bench-runner.git";
    rev = "60f52ddeb5e5ca67edcfc0b7d7926a3cd5369f0a";
    # No submodules, which is what update-llama-bench-runner assumes when prefetching.
    fetchSubmodules = false;
    hash = "sha256-wRapC5mjsPuUEC2qiaof6vpSTraNODNhh1RorQgarKQ=";
  };

  # The repo's scripts, packaged in bin/ (read-only store).
  llamaBenchRunnerScripts = pkgs.runCommand "llama-bench-runner-scripts" {} ''
    mkdir -p $out/bin
    cp ${llamaBenchRunner}/scripts/* $out/bin/
    chmod +x $out/bin/*
    patchShebangs $out/bin
  '';
in {
  imports = [
    ../../common
  ];

  networking.hostName = hostName;

  users.users.${hostName} = {
    isNormalUser = true;

    extraGroups = ["wheel" "render" "video"];

    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGApUnvphJshC3LJ4QxDu8fm3JqEnSWZ6ewhf6gQuF7V PopOS OCT 2024"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFeASXjLf7TjNTxO5CZ4Aa6z8hyFG0CXAe4FhcpZOEp6 NixOS-CI MAY 2026"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDlKHmpR2Qi9jTM1xUWvtYT2uKpwl7d063DyowiZ4hBU ibuki"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOItHReLpLr0DZHohVHBdqu7CePpsuQ3ANa0UsUX0xj+ pablo.bugarin.camara@gmail.com"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG1kMUYO4VHcsypjXFxKcmdzki6/L0dcIW2BW2eopotS deploy-runner"
    ];

    packages = with pkgs; [
      tree
      git
      curl
      wget
      jq
      magic-wormhole
      vulkan-tools
      radeontop
      llamaBenchRunnerScripts
    ];
  };

  services.llama-swap = {
    enable = true;
    listenAddress = "0.0.0.0";
    port = 8080;
    openFirewall = true; # Adds the port to allowedTCPPorts. Needed with Proxmox?
    settings = {
      includeAliasesInList = true;
      # Discovers every model in ./models; archived/ stays out.
      models = import ./models {
        inherit pkgs;
        llama-server = llama-server-delayed;
      };
    };
  };

  systemd.services.llama-swap = {
    environment =
      {
        MESA_SHADER_CACHE_DIR = "/var/cache/llama-swap";
        XDG_CACHE_HOME = "/var/cache/llama-swap";
      }
      // gpuEnv;
    serviceConfig = {
      CacheDirectory = "llama-swap";
    };
  };

  # Runtime GPU drivers, depending on the chosen profile.
  # The llama-cpp build already pulls them in as buildInputs via .override.
  hardware.graphics.extraPackages = with pkgs;
    if isLlamacppRocm
    then [
      rocmPackages.clr
      rocmPackages.clr.icd
    ]
    else [
      vulkan-loader
    ];

  nix.settings.trusted-users = ["nixos-llamaswap-rocm" "nixos-llamaswap-vulkan"];

  nix.settings.experimental-features = ["nix-command" "flakes"];

  system.stateVersion = "26.05";
}