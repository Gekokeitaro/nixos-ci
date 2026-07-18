{pkgs}:
pkgs.writeShellApplication {
  name = "update-llama-cpp";
  runtimeInputs = with pkgs; [curl jq nix-prefetch-github gnused git];
  text = ''
    REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
    TARGET_FILE="$REPO_ROOT/packages/llama-cpp/default.nix"

    if [ ! -f "$TARGET_FILE" ]; then
      echo "Error: Could not find packages/llama-cpp/default.nix at $TARGET_FILE" >&2
      exit 1
    fi

    echo "Fetching latest llama.cpp release from GitHub..."
    LATEST_TAG=$(curl -sf https://api.github.com/repos/ggml-org/llama.cpp/releases/latest | jq -r '.tag_name')

    if [ -z "$LATEST_TAG" ] || [ "$LATEST_TAG" = "null" ]; then
      echo "Error: Failed to fetch latest release tag" >&2
      exit 1
    fi

    VERSION="''${LATEST_TAG#b}"
    echo "Latest version found: $VERSION ($LATEST_TAG)"

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

    echo "Updating target file..."
    sed -i "s/llamacppVersion = \"[^\"]*\";/llamacppVersion = \"$VERSION\";/" "$TARGET_FILE"
    sed -i "s|llamacppHash = \"[^\"]*\";|llamacppHash = \"$HASH\";|" "$TARGET_FILE"

    echo "Successfully updated llama-cpp package to version $VERSION with hash $HASH"
  '';
}
