{
  pkgs,
  isLlamacppRocm,
}: let
  lib = pkgs.lib;
  llamacppVersion = "v0.3.0";
  llamacppHash = "sha256-vVq7+eUN6NXZuqm7Jwlr4iFDV1PjNzQ6nK9AR2zvZYM=";
  llamacppNpmHash = "sha256-2Q7XhaLAArmviOLdQsNbYTfdyDE5pW9lR26cRHEVl9k=";
  targetGPU = "gfx1035";
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
        tag = "${version}";
        hash = llamacppHash;
      };

      npmDepsHash = llamacppNpmHash;

      # Disable Nix's march=native stripping
      preConfigure = ''
        prependToVar cmakeFlags "-DLLAMA_BUILD_COMMIT:STRING=b${llamacppVersion}"
      '';

      # https://github.com/ggml-org/llama.cpp/issues/21724
      # https://drakerossman.com/blog/how-to-patch-a-package-source-on-nixos
      # 30-May-26: En mi caso, DeviceLost sólo se arregla con el valor a 1, a costa de una pérdida significativa de rendimiento.
      # El workaround viable sigue siendo aumentar el lockup_timeout.
      # Sin embargo he encontrado mejoras de rendimiento experimentando con nodes_per_submit, por lo que dejo el parche para hacer fine-tuning.
      # 24-Jun-26: https://github.com/ggml-org/llama.cpp/pull/24872 -> FIXED b9782
      #postPatch = ''
      #  substituteInPlace ggml/src/ggml-vulkan/ggml-vulkan.cpp \
      #  --replace-fail "int nodes_per_submit = 100;" "int nodes_per_submit = 1;"
      #'';

      # Enable native CPU optimizations (AVX, AVX2, etc.)
      cmakeFlags =
        # Nos cargamos la flag con el valor por defecto para evitar que compile para todas las arquitecturas.
        (builtins.filter (f: !(lib.hasPrefix "-DCMAKE_HIP_ARCHITECTURES" f)) oldAttrs.cmakeFlags or [])
        ++ [
          "-DCMAKE_BUILD_TYPE=Release"
          "-DGGML_NATIVE=ON"
        ]
        ++ lib.optionals isLlamacppRocm [
          "-DCMAKE_HIP_ARCHITECTURES=${targetGPU}"
          "-DGPU_TARGETS=${targetGPU}"
        ];
    }
  )
