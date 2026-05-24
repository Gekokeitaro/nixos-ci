{
  pkgs,
  isLlamacppRocm,
}: let
  lib = pkgs.lib;
  llamacppVersion = "9305";
  llamacppHash = "sha256-TsleTV12rW+35OvHxkWJo42Lhp6FkSyozxiK71yjfRg=";
  gpuArch = "gfx1035";
in
  (
    pkgs.llama-cpp.override {
      rocmSupport = isLlamacppRocm;
      blasSupport = true;
      vulkanSupport = !isLlamacppRocm;
    }
  ).overrideAttrs (
    oldAttrs: rec {
      version = llamacppVersion;
      src = pkgs.fetchFromGitHub {
        owner = "ggml-org";
        repo = "llama.cpp";
        tag = "b${version}";
        hash = llamacppHash;
        leaveDotGit = true;
        postFetch = ''
          git -C "$out" rev-parse --short HEAD > $out/COMMIT
          find "$out" -name .git -print0 | xargs -0 rm -rf
        '';
      };

      nativeBuildInputs =
        builtins.filter
        (x: x != pkgs.npmHooks.npmConfigHook && (x.pname or "") != "nodejs")
        oldAttrs.nativeBuildInputs;

      npmDeps = null;

      # Disable Nix's march=native stripping
      preConfigure = ''
        prependToVar cmakeFlags "-DLLAMA_BUILD_COMMIT:STRING=$(cat COMMIT)"
      '';

      # Enable native CPU optimizations (AVX, AVX2, etc.)
      cmakeFlags =
        # Nos cargamos la flag con el valor por defecto para evitar que compile para todas las arquitecturas.
        (builtins.filter (f: !(lib.hasPrefix "-DCMAKE_HIP_ARCHITECTURES" f)) oldAttrs.cmakeFlags or [])
        ++ [
          "-DCMAKE_BUILD_TYPE=Release"
          "-DGGML_NATIVE=ON"
          "-DLLAMA_BUILD_UI=OFF"
        ]
        ++ lib.optionals isLlamacppRocm [
          "-DCMAKE_HIP_ARCHITECTURES=${gpuArch}"
        ];
    }
  )
