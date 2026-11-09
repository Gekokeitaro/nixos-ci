{pkgs}:
pkgs.writeShellApplication {
  name = "update-llama-cpp";
  runtimeInputs = with pkgs; [curl jq nix-prefetch-github gnused git nix coreutils];
  text = ''
    REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
    TARGET_FILE="$REPO_ROOT/hosts/llamaswap-lxc/packages/llama-cpp/default.nix"

    if [ ! -f "$TARGET_FILE" ]; then
      echo "Error: Could not find hosts/llamaswap-lxc/packages/llama-cpp/default.nix at $TARGET_FILE" >&2
      exit 1
    fi

    echo "Fetching latest llama.cpp release from GitHub..."
    LATEST_TAG=$(curl -sf https://api.github.com/repos/ggml-org/llama.cpp/releases/latest | jq -r '.tag_name')

    if [ -z "$LATEST_TAG" ] || [ "$LATEST_TAG" = "null" ]; then
      echo "Error: Failed to fetch latest release tag" >&2
      exit 1
    fi

    VERSION="$LATEST_TAG"
    echo "Latest release: $LATEST_TAG"

    CURRENT_VERSION=$(sed -n 's/.*llamacppVersion = "\([^"]*\)".*/\1/p' "$TARGET_FILE")
    if [ "$CURRENT_VERSION" = "$VERSION" ]; then
      echo "llama.cpp is already up to date (version $VERSION)."
      exit 0
    fi

    echo "Prefetching hash for $LATEST_TAG..."
    HASH=$(nix-prefetch-github ggml-org llama.cpp --rev "$LATEST_TAG" | jq -r '.hash')

    if [ -z "$HASH" ] || [ "$HASH" = "null" ]; then
      echo "Error: Failed to prefetch hash" >&2
      exit 1
    fi

    OLD_HASH=$(sed -n 's/.*llamacppHash = "\([^"]*\)".*/\1/p' "$TARGET_FILE")
    OLD_NPM_HASH=$(sed -n 's/.*llamacppNpmHash = "\([^"]*\)".*/\1/p' "$TARGET_FILE")
    NPM_HASH=""
    restore_on_failure() {
      if [ -z "''${NPM_HASH:-}" ]; then
        sed -i "s/llamacppVersion = \"[^\"]*\";/llamacppVersion = \"$CURRENT_VERSION\";/" "$TARGET_FILE"
        sed -i "s|llamacppHash = \"[^\"]*\";|llamacppHash = \"$OLD_HASH\";|" "$TARGET_FILE"
        sed -i "s|llamacppNpmHash = \"[^\"]*\";|llamacppNpmHash = \"$OLD_NPM_HASH\";|" "$TARGET_FILE"
      fi
    }
    trap restore_on_failure EXIT

    echo "Updating version and source hash..."
    sed -i "s/llamacppVersion = \"[^\"]*\";/llamacppVersion = \"$VERSION\";/" "$TARGET_FILE"
    sed -i "s|llamacppHash = \"[^\"]*\";|llamacppHash = \"$HASH\";|" "$TARGET_FILE"

    # Refrescar npmDepsHash. Nix solo revela el hash esperado tras un fallo de
    # coincidencia, así que escribimos uno falso y construimos solo el FOD de npm.
    echo "Refreshing npmDepsHash (forcing an expected hash mismatch)..."
    FAKE_NPM_HASH="sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="
    sed -i "s|llamacppNpmHash = \"[^\"]*\";|llamacppNpmHash = \"$FAKE_NPM_HASH\";|" "$TARGET_FILE"

    SYSTEM=$(nix eval --raw --impure --expr builtins.currentSystem)
    NPM_EXPR="
    let
      flake = builtins.getFlake \"$REPO_ROOT\";
      pkgs = builtins.getAttr \"$SYSTEM\" flake.inputs.nixpkgs.legacyPackages;
      pkg = import \"$REPO_ROOT/hosts/llamaswap-lxc/packages/llama-cpp\" {
        inherit pkgs;
        isLlamacppRocm = false;
      };
    in pkg.npmDeps
    "
    set +e
    BUILD_OUT=$(nix build --no-link --impure --extra-experimental-features "nix-command flakes" --expr "$NPM_EXPR" 2>&1)
    set -e
    NPM_HASH=$(printf '%s\n' "$BUILD_OUT" | sed -n 's/.*got:[[:space:]]*\(sha256-[^[:space:]]*\).*/\1/p')
    NPM_HASH=''${NPM_HASH%%$'\n'*}

    if [ -z "$NPM_HASH" ]; then
      echo "Error: could not determine npmDepsHash; previous value restored." >&2
      printf '%s\n' "$BUILD_OUT" >&2
      exit 1
    fi

    sed -i "s|llamacppNpmHash = \"[^\"]*\";|llamacppNpmHash = \"$NPM_HASH\";|" "$TARGET_FILE"

    echo "Successfully updated llama-cpp package to version $VERSION"
    echo "  src hash: $HASH"
    echo "  npm hash: $NPM_HASH"
  '';
}
