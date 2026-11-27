{
  pkgs,
  isLlamacppRocm,
}: let
  lib = pkgs.lib;

  # Every value that changes on a llama.cpp upgrade lives there, and nowhere else.
  versions = import ./versions.nix;

  targetGPU = "gfx1035";

  # nixpkgs reads these two from git, which a release tarball does not ship; they
  # feed `llama-server --version`, `/props` and the web UI. Derived from the pin
  # above, never typed: a tag in `rev` is what made `/props` report a build_info
  # that matched no commit.
  buildCommit = builtins.substring 0 7 versions.rev;
  buildNumber = lib.removePrefix "b" versions.buildNumber;

  src = pkgs.fetchFromGitHub {
    owner = "ggml-org";
    repo = "llama.cpp";
    rev = versions.rev;
    hash = versions.hash;
  };
in
  assert lib.assertMsg (builtins.match "v[0-9]+\\.[0-9]+\\.[0-9]+" versions.version != null)
  "llama-cpp: versions.version must be a release tag such as v1.0.0; got '${versions.version}'.";
  assert lib.assertMsg (!(lib.hasPrefix "v" versions.rev))
  "llama-cpp: versions.rev is '${versions.rev}', a tag where a commit belongs. Resolve the tag's commit (versions.nix says why) and paste the 40-hex hash.";
  assert lib.assertMsg (builtins.match "[0-9a-f]{40}" versions.rev != null)
  "llama-cpp: versions.rev must be exactly 40 lowercase hex characters; got '${versions.rev}'.";
  assert lib.assertMsg (builtins.match "b[0-9]+" versions.buildNumber != null)
  "llama-cpp: versions.buildNumber must look like b12359; got '${versions.buildNumber}'.";
  assert lib.assertMsg (builtins.pathExists "${src}/ui/apps/chat")
  "llama-cpp: ${versions.version} has no ui/apps/chat. The web UI moves between majors (v1.1.0 took it from tools/ui), so npmRoot and this assert need the path of the version being pinned.";
  (
    pkgs.llama-cpp.override {
      rocmSupport = isLlamacppRocm;
      blasSupport = true;
      vulkanSupport = !isLlamacppRocm;
    }
  )
  .overrideAttrs (
    oldAttrs: let
      # nixpkgs supplies this pair from its own pin (llama.cpp 0.8.0:
      # `-DLLAMA_BUILD_NUMBER:STRING=11960`, `-DLLAMA_BUILD_COMMIT:STRING=8642541`),
      # which is the whole reason `/props` once answered `b11960-v1.0.0`. The pair
      # is dropped in `cmakeFlags` and replaced from `versions.nix` in
      # `preConfigure`: a leftover would win over ours and put the stale values
      # back, silently.
      inheritedBuildFlags =
        builtins.filter
        (flag: lib.hasPrefix "-DLLAMA_BUILD_NUMBER" flag || lib.hasPrefix "-DLLAMA_BUILD_COMMIT" flag)
        (oldAttrs.cmakeFlags or []);
      hasFlag = prefix: lib.any (flag: lib.hasPrefix prefix flag) inheritedBuildFlags;
    in
      assert lib.assertMsg (builtins.length inheritedBuildFlags == 2 && hasFlag "-DLLAMA_BUILD_NUMBER" && hasFlag "-DLLAMA_BUILD_COMMIT")
      "llama-cpp: expected nixpkgs to pass one -DLLAMA_BUILD_NUMBER and one -DLLAMA_BUILD_COMMIT, found [${lib.concatStringsSep " " inheritedBuildFlags}]. If upstream dropped or renamed them, drop the filter in cmakeFlags and keep preConfigure; if it changed their shape, update that filter.";
      {
        version = versions.version;
        inherit src;

        npmDepsHash = versions.npmHash;

        # Pinned, not inherited: the web UI moves between majors. nixpkgs still
        # points at tools/ui, while v1.1.0 moved it to ui/apps/chat. This is the
        # line that fails on a major bump, after the pathExists assert above.
        npmRoot = "ui/apps/chat";

        nativeCheckInputs =
          [(pkgs.python3.withPackages (ps: [ps.numpy ps.torch ps.safetensors ps.transformers]))]
          ++ (oldAttrs.nativeCheckInputs or []);

        # nixpkgs' pair is filtered out of `cmakeFlags` above; these two are the
        # only build metadata the compiler sees, and both come from versions.nix.
        preConfigure = ''
          prependToVar cmakeFlags "-DLLAMA_BUILD_NUMBER:STRING=${buildNumber}"
          prependToVar cmakeFlags "-DLLAMA_BUILD_COMMIT:STRING=${buildCommit}"
        '';

        # https://github.com/ggml-org/llama.cpp/issues/21724
        # https://drakerossman.com/blog/how-to-patch-a-package-source-on-nixos
        # 30-May-26: In my case, DeviceLost is only fixed with the value set to 1, at the cost of a significant performance loss.
        # The viable workaround is still raising lockup_timeout.
        # However I have found performance gains experimenting with nodes_per_submit, so I keep the patch for fine-tuning.
        # 24-Jun-26: https://github.com/ggml-org/llama.cpp/pull/24872 -> FIXED b9782
        #postPatch = ''
        #  substituteInPlace ggml/src/ggml-vulkan/ggml-vulkan.cpp \
        #  --replace-fail "int nodes_per_submit = 100;" "int nodes_per_submit = 1;"
        #'';

        # Enable native CPU optimizations (AVX, AVX2, etc.)
        cmakeFlags =
          # Drop the stale build metadata and the flag's default value so it does
          # not build for every architecture.
          (builtins.filter
            (f:
              !(lib.hasPrefix "-DLLAMA_BUILD_NUMBER" f)
              && !(lib.hasPrefix "-DLLAMA_BUILD_COMMIT" f)
              && !(lib.hasPrefix "-DCMAKE_HIP_ARCHITECTURES" f))
            oldAttrs.cmakeFlags or [])
          ++ [
            "-DCMAKE_BUILD_TYPE=Release"
            "-DGGML_NATIVE=ON"
            "-DGGML_CUDA_FA_ALL_QUANTS=ON"
          ]
          ++ lib.optionals isLlamacppRocm [
            "-DCMAKE_HIP_ARCHITECTURES=${targetGPU}"
            "-DGPU_TARGETS=${targetGPU}"
          ];
      }
  )
