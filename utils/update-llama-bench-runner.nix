{pkgs}:
pkgs.writeShellApplication {
  name = "update-llama-bench-runner";
  runtimeInputs = with pkgs; [coreutils gawk git gnused jq nix-prefetch-git];
  text = ''
    REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
    TARGET_FILE="$REPO_ROOT/hosts/llamaswap-lxc/configuration.nix"
    REPO_URL="https://gitlab.com/Gekokeitaro/llama-bench-runner.git"
    BRANCH="main"

    if [ ! -f "$TARGET_FILE" ]; then
      echo "Error: $TARGET_FILE does not exist" >&2
      exit 1
    fi

    # The pin lives in the host's llamaBenchRunner block; it is read from there so
    # the command stays correct if the file gains other fetchgit calls.
    read_pin() {
      sed -n '/llamaBenchRunner = pkgs.fetchgit/,/};/s/.*'"$1"' = "\([^"]*\)".*/\1/p' "$TARGET_FILE"
    }
    CURRENT_REV=$(read_pin rev)
    OLD_HASH=$(read_pin hash)
    if [ -z "$CURRENT_REV" ] || [ -z "$OLD_HASH" ]; then
      echo "Error: the llamaBenchRunner block of $TARGET_FILE has no rev and hash" >&2
      exit 1
    fi

    echo "Reading the HEAD of $BRANCH at $REPO_URL..."
    if ! REMOTE=$(git ls-remote "$REPO_URL" "refs/heads/$BRANCH" 2>&1); then
      # The runner's network does not always see GitLab. The committed pin is valid
      # and reproducible, so a failure here does not justify blocking the deploy.
      echo "Warning: could not read the remote ($REMOTE). Keeping $CURRENT_REV." >&2
      exit 0
    fi
    NEW_REV=$(printf '%s\n' "$REMOTE" | awk 'NR == 1 {print $1}')
    if [ -z "$NEW_REV" ]; then
      echo "Warning: the remote returned no rev for $BRANCH. Keeping $CURRENT_REV." >&2
      exit 0
    fi

    if [ "$NEW_REV" = "$CURRENT_REV" ]; then
      echo "llama-bench-runner is already at $CURRENT_REV; nothing to update."
      exit 0
    fi

    echo "Current pin: $CURRENT_REV"
    echo "New pin:     $NEW_REV"
    echo "Computing the checkout hash..."

    if ! PREFETCH=$(nix-prefetch-git --url "$REPO_URL" --rev "$NEW_REV" --quiet 2>&1); then
      echo "Error: nix-prefetch-git failed; the pin is left untouched." >&2
      printf '%s\n' "$PREFETCH" >&2
      exit 1
    fi
    NEW_HASH=$(printf '%s\n' "$PREFETCH" | jq -r '.hash // empty')
    if [ -z "$NEW_HASH" ]; then
      echo "Error: nix-prefetch-git returned no usable hash; the pin is left untouched." >&2
      printf '%s\n' "$PREFETCH" >&2
      exit 1
    fi

    # A single sed pass replacing both exact values: if anything fails, the
    # file stays as it was.
    sed -i -e "s|$CURRENT_REV|$NEW_REV|" -e "s|$OLD_HASH|$NEW_HASH|" "$TARGET_FILE"

    if [ "$(read_pin rev)" != "$NEW_REV" ] || [ "$(read_pin hash)" != "$NEW_HASH" ]; then
      echo "Error: the substitution was not written to $TARGET_FILE" >&2
      exit 1
    fi

    echo "Updated llama-bench-runner"
    echo "  rev:  $CURRENT_REV -> $NEW_REV"
    echo "  hash: $OLD_HASH -> $NEW_HASH"
    echo "The change is not committed: the deploy uses the new pin and the job log is its record."
  '';
}
