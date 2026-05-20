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
