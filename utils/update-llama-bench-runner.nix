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
      echo "Error: no existe $TARGET_FILE" >&2
      exit 1
    fi

    # El pin vive en el bloque llamaBenchRunner del host; se lee de ahí para que el
    # comando siga siendo correcto si el fichero gana otros fetchgit.
    read_pin() {
      sed -n '/llamaBenchRunner = pkgs.fetchgit/,/};/s/.*'"$1"' = "\([^"]*\)".*/\1/p' "$TARGET_FILE"
    }
    CURRENT_REV=$(read_pin rev)
    OLD_HASH=$(read_pin hash)
    if [ -z "$CURRENT_REV" ] || [ -z "$OLD_HASH" ]; then
      echo "Error: el bloque llamaBenchRunner de $TARGET_FILE no tiene rev y hash" >&2
      exit 1
    fi

    echo "Leyendo el HEAD de $BRANCH en $REPO_URL..."
    if ! REMOTE=$(git ls-remote "$REPO_URL" "refs/heads/$BRANCH" 2>&1); then
      # La red del runner no siempre ve GitLab. El pin commiteado es válido y
      # reproducible, así que un fallo aquí no justifica bloquear el despliegue.
      echo "Aviso: no se pudo leer el remoto ($REMOTE). Se mantiene $CURRENT_REV." >&2
      exit 0
    fi
    NEW_REV=$(printf '%s\n' "$REMOTE" | awk 'NR == 1 {print $1}')
    if [ -z "$NEW_REV" ]; then
      echo "Aviso: el remoto no devolvió ninguna rev para $BRANCH. Se mantiene $CURRENT_REV." >&2
      exit 0
    fi

    if [ "$NEW_REV" = "$CURRENT_REV" ]; then
      echo "llama-bench-runner ya está en $CURRENT_REV; no hay nada que actualizar."
      exit 0
    fi

    echo "Pin actual: $CURRENT_REV"
    echo "Pin nuevo:  $NEW_REV"
    echo "Calculando el hash del checkout..."

    if ! PREFETCH=$(nix-prefetch-git --url "$REPO_URL" --rev "$NEW_REV" --quiet 2>&1); then
      echo "Error: nix-prefetch-git falló; el pin no se toca." >&2
      printf '%s\n' "$PREFETCH" >&2
      exit 1
    fi
    NEW_HASH=$(printf '%s\n' "$PREFETCH" | jq -r '.hash // empty')
    if [ -z "$NEW_HASH" ]; then
      echo "Error: nix-prefetch-git no devolvió un hash utilizable; el pin no se toca." >&2
      printf '%s\n' "$PREFETCH" >&2
      exit 1
    fi

    # Una sola pasada de sed sustituyendo los dos valores exactos: si algo falla, el
    # fichero queda como estaba.
    sed -i -e "s|$CURRENT_REV|$NEW_REV|" -e "s|$OLD_HASH|$NEW_HASH|" "$TARGET_FILE"

    if [ "$(read_pin rev)" != "$NEW_REV" ] || [ "$(read_pin hash)" != "$NEW_HASH" ]; then
      echo "Error: la sustitución no quedó escrita en $TARGET_FILE" >&2
      exit 1
    fi

    echo "Actualizado llama-bench-runner"
    echo "  rev:  $CURRENT_REV -> $NEW_REV"
    echo "  hash: $OLD_HASH -> $NEW_HASH"
    echo "El cambio no se commitea: el despliegue usa el pin nuevo y el log del job es su registro."
  '';
}
