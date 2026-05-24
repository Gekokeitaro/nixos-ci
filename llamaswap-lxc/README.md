# NixOS LXC

Plantilla para crear LXC de NixOS, utilizando de base: -
https://gysli.ng/posts/tech/proxmox-nixos/

## Instrucciones

1. Editar el hostName y SSH public key (para conexión por SSH)
2. Generamos el LXC con:
   `nixos-rebuild build-image --image-variant lxc --flake .`

## Notas

> [!NOTE]
>
> - El resultado es un softlink apuntando al `tar.gz` de la imagen en `store`
> - Nada más iniciar el contenedor, lanzar `nix-channel --update`
> - Los ficheros de configuración (`flake.nix`, `configuration.nix`...) no
>   viajan a la imagen del contenedor, hay que volver a crearlos dentro.

# Obtener hash del source de llama.cpp

nix shell nixpkgs#nix-prefetch-github nixpkgs#jq nixpkgs#curl

# Latest release de llama.cpp

LATEST=$(curl -sf
https://api.github.com/repos/ggml-org/llama.cpp/releases/latest | jq -r
'.tag_name') echo "Latest: $LATEST"

# Obtener hash SRI para fetchFromGitHub

# Docs: https://nixos.org/manual/nixpkgs/stable/#fetchfromgithub

nix-prefetch-github ggml-org llama.cpp --rev "$LATEST"

# → { "hash": "sha256-XXXX=", "rev": "bNNNN" }
