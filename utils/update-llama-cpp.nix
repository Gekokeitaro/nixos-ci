{pkgs}:
pkgs.writeShellApplication {
  name = "update-llama-cpp";
  runtimeInputs = with pkgs; [curl jq nix-prefetch-github git nix coreutils gnused];
  text = ''
    REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
    PACKAGE_DIR="$REPO_ROOT/hosts/llamaswap-lxc/packages/llama-cpp"
    TARGET_FILE="$PACKAGE_DIR/versions.nix"
    API="https://api.github.com/repos/ggml-org/llama.cpp"

    if [ ! -f "$TARGET_FILE" ]; then
      echo "Error: $TARGET_FILE not found; refusing to write a pin it cannot verify." >&2
      exit 1
    fi

    echo "Fetching the latest llama.cpp release tag from GitHub..."
    TAG=$(curl -sf "$API/releases/latest" | jq -r '.tag_name')

    # Upstream tags may name the build and commit they were cut from
    # (v1.0.0-b12359-b1b770d). That suffix is checked below and never reaches
    # `version`, which is what `/props` reports.
    if [[ "$TAG" =~ ^(v[0-9]+\.[0-9]+\.[0-9]+)(-b([0-9]+)-([0-9a-f]{7,40}))?$ ]]; then
      VERSION="''${BASH_REMATCH[1]}"
      ANNOUNCED_BUILD="''${BASH_REMATCH[3]}"
      ANNOUNCED_REV="''${BASH_REMATCH[4]}"
    else
      echo "Error: GitHub returned no release tag of the form vX.Y.Z[-b<build>-<commit>] (got '$TAG')." >&2
      exit 1
    fi
    echo "Latest release: $TAG (version $VERSION)"

    CURRENT_VERSION=$(nix eval --raw --impure --expr "(import \"$TARGET_FILE\").version")
    if [ "$CURRENT_VERSION" = "$VERSION" ]; then
      echo "llama.cpp is already pinned to $VERSION; nothing to do."
      exit 0
    fi

    echo "Resolving the commit behind $TAG and prefetching its source..."
    PREFETCH=$(nix-prefetch-github ggml-org llama.cpp --rev "$TAG")
    SOURCE_REV=$(printf '%s' "$PREFETCH" | jq -r '.rev')
    SOURCE_HASH=$(printf '%s' "$PREFETCH" | jq -r '.hash')

    if [[ ! "$SOURCE_REV" =~ ^[0-9a-f]{40}$ ]]; then
      echo "Error: nix-prefetch-github returned no 40-hex commit for $TAG (got '$SOURCE_REV')." >&2
      exit 1
    fi
    if [[ ! "$SOURCE_HASH" =~ ^sha256-[A-Za-z0-9+/]+=*$ ]]; then
      echo "Error: nix-prefetch-github returned no sha256 hash for $TAG (got '$SOURCE_HASH')." >&2
      exit 1
    fi

    # llama.cpp tags are annotated: the ref points at a tag object, which points
    # at the commit. Compare our resolved commit with the one GitHub reports, so
    # a tag object pasted where a commit belongs cannot reach versions.nix.
    echo "Checking the commit GitHub reports for $TAG..."
    TAG_REF=$(curl -sf "$API/git/ref/tags/$TAG")
    TAG_KIND=$(printf '%s' "$TAG_REF" | jq -r '.object.type')
    TAG_SHA=$(printf '%s' "$TAG_REF" | jq -r '.object.sha')
    if [ "$TAG_KIND" = "tag" ]; then
      TAG_COMMIT=$(curl -sf "$API/git/tags/$TAG_SHA" | jq -r '.object.sha')
    else
      TAG_COMMIT="$TAG_SHA"
    fi
    if [[ ! "$TAG_COMMIT" =~ ^[0-9a-f]{40}$ ]]; then
      echo "Error: could not read the commit behind $TAG from the GitHub API (rate limit, or the tag moved). Retry later." >&2
      exit 1
    fi
    if [ "$TAG_COMMIT" != "$SOURCE_REV" ]; then
      echo "Error: $TAG resolves to $SOURCE_REV locally but GitHub reports $TAG_COMMIT." >&2
      exit 1
    fi

    echo "Reading the build number from the release asset..."
    NIGHTLY_TAG=$(curl -sfL "https://github.com/ggml-org/llama.cpp/releases/download/$TAG/nightly-tag.txt")
    if [[ ! "$NIGHTLY_TAG" =~ ^b[0-9]+$ ]]; then
      echo "Error: nightly-tag.txt of $TAG did not return a build number (got '$NIGHTLY_TAG')." >&2
      echo "The release asset moved or is missing; refusing to write build metadata nobody published." >&2
      exit 1
    fi

    # When the tag names its own build and commit, they must agree with what git
    # and the release asset report.
    if [ -n "$ANNOUNCED_BUILD" ] && [ "b$ANNOUNCED_BUILD" != "$NIGHTLY_TAG" ]; then
      echo "Error: $TAG announces build b$ANNOUNCED_BUILD but nightly-tag.txt says $NIGHTLY_TAG." >&2
      exit 1
    fi
    if [ -n "$ANNOUNCED_REV" ]; then
      case "$SOURCE_REV" in
        "$ANNOUNCED_REV"*) ;;
        *)
          echo "Error: $TAG announces commit $ANNOUNCED_REV but git resolves the tag to $SOURCE_REV." >&2
          exit 1
          ;;
      esac
    fi

    # All-or-nothing: the file is replaced whole, and the previous copy comes back
    # untouched if any later step fails.
    BACKUP=$(mktemp)
    cp "$TARGET_FILE" "$BACKUP"
    COMMITTED=0

    restore_and_exit() {
      rc=$?
      trap - EXIT
      if [ "$COMMITTED" -eq 0 ]; then
        cp "$BACKUP" "$TARGET_FILE"
        echo "Failed: restored the previous $TARGET_FILE." >&2
      fi
      rm -f "$BACKUP" "''${TMPFILE:-}"
      exit "$rc"
    }
    trap restore_and_exit EXIT

    write_versions() {
      local npm_hash="$1"
      tmp=$(mktemp "$PACKAGE_DIR/.versions.nix.XXXXXX")
      TMPFILE="$tmp"
      cat > "$tmp" <<EOF
    # The only file of this package with values that change on an upgrade.
    # Written whole by \`nix run .#update-llama-cpp\`, never edited value by value.
    {
      version = "$VERSION";
      # Commit behind the tag, not the tag: llama.cpp tags are annotated.
      rev = "$SOURCE_REV";
      hash = "$SOURCE_HASH";
      npmHash = "$npm_hash";
      # Upstream build number of that commit, from the release's nightly-tag.txt.
      buildNumber = "$NIGHTLY_TAG";
    }
    EOF
      chmod 644 "$tmp"
      mv "$tmp" "$TARGET_FILE"
    }

    FAKE_NPM_HASH="sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="
    echo "Writing the candidate pin with a fake npm hash, so the FOD mismatch reveals the real one..."
    write_versions "$FAKE_NPM_HASH"

    SYSTEM=$(nix eval --raw --impure --expr builtins.currentSystem)
    NPM_EXPR="
    let
      flake = builtins.getFlake \"$REPO_ROOT\";
      pkgs = builtins.getAttr \"$SYSTEM\" flake.inputs.nixpkgs.legacyPackages;
      pkg = import \"$PACKAGE_DIR\" {
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
      echo "Error: could not determine npmHash from the npm-deps build." >&2
      printf '%s\n' "$BUILD_OUT" >&2
      exit 1
    fi

    write_versions "$NPM_HASH"

    echo "Checking that the written file evaluates to the values just resolved..."
    EVAL_OUT=$(nix eval --raw --impure --expr "(import \"$TARGET_FILE\").rev + \" \" + (import \"$TARGET_FILE\").buildNumber")
    if [ "$EVAL_OUT" != "$SOURCE_REV $NIGHTLY_TAG" ]; then
      echo "Error: $TARGET_FILE evaluates to '$EVAL_OUT', expected '$SOURCE_REV $NIGHTLY_TAG'." >&2
      exit 1
    fi

    COMMITTED=1
    echo "Updated llama-cpp to $VERSION (release tag $TAG)"
    echo "  rev:         $SOURCE_REV"
    echo "  src hash:    $SOURCE_HASH"
    echo "  npm hash:    $NPM_HASH"
    echo "  buildNumber: $NIGHTLY_TAG"
    echo "  /props build_info after the next deploy: $NIGHTLY_TAG-$(printf '%s' "$SOURCE_REV" | cut -c1-7)"
  '';
}
