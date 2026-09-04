# NixOS OmniRoute

Host para el AI gateway OmniRoute de Diego Souza (`diegosouzapw/omniroute`),
corriendo como contenedor OCI con Podman.

## Notas

> [!NOTE]
>
> - El resultado es un softlink apuntando al `tar.gz` de la imagen en `store`
> - Nada más iniciar el contenedor, lanzar `nix-channel --update`
> - Los ficheros de configuración (`flake.nix`, `configuration.nix`...) no
>   viajan a la imagen del contenedor, hay que volver a crearlos dentro.
> - Las claves secretas (`OMNIROUTE_WS_BRIDGE_SECRET`, `INITIAL_PASSWORD`)
>   deben generarse e inyectarse en el `environment` del contenedor
>   fuera de la imagen.
> - Los datos persistentes viven en el volumen `omniroute-data:/app/data`.
