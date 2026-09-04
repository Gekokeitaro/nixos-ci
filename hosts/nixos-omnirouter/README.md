# NixOS OmniRouter

Host para el AI gateway OmniRoute de Diego Souza.

## Notas

> [!NOTE]
>
> - El resultado es un softlink apuntando al `tar.gz` de la imagen en `store`
> - Nada más iniciar el contenedor, lanzar `nix-channel --update`
> - Los ficheros de configuración (`flake.nix`, `configuration.nix`...) no
>   viajan a la imagen del contenedor, hay que volver a crearlos dentro.
> - Las claves secretas (`JWT_SECRET`, `API_KEY_SECRET`,
>   `INITIAL_PASSWORD`, `OMNIROUTE_WS_BRIDGE_SECRET`) deben generarse
>   e inyectarse en el entorno del servicio `omniroute` fuera de la imagen.