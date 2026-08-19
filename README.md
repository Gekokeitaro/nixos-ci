# NixOS LXC

> [!summary] Repo para crear, desplegar y actualizar los LXC de mi homelab.

## Hosts

| Hostname               | Función                                                                                                                                    |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------ |
| nixos-ci               | En vías de deprecación [^*]. Máquina de desarrollo, creación y actualización de LXC.                                                       |
| nixos-llamaswap-vulkan | llama.cpp + llamaswap para servir modelos locales. [^**]                                                                                   |
| nixos-calibre-web-auto | Levanta [Calibre Web Automated](https://github.com/crocodilestick/Calibre-Web-Automated) para servir mis ebooks entre varios dispositivos. |
| nixos-pihole           | Abandonado. Nice to have pero ahora mismo no me sale a cuenta.                                                                             |
| (WIP) nixos-forgejo    | Servidor para mantener mis repos y sincronizarlos con otros servicios, con CI/CD para los LXC.                                             |

[^*] Seguramente se quede en modo mantenimiento, pero la idea es llevar el CI/CD
de los LXC a Forgejo.

[^**] También incluye Omniroute, aunque la idea será migrarlo a otro LXC.

> [!note] Todos los LXC tienen NVF (Neovim) cómo editor de texto para realizar
> ajustes y tests.

## Comandos

| Comando                                                                          | Acción                                                                   |
| -------------------------------------------------------------------------------- | ------------------------------------------------------------------------ |
| `nix flake show .`                                                               | Muestra los comandos y hosts del `flake.nix`                             |
| `nixos-rebuild build-image --image-variant lxc --flake .#<host>`                 | Deprecado[^*]. Genera una imagen LXC basada en la configuración del host |
| `nixos-rebuild switch --flake .#<host> --target-host <user>@<ip> --elevate=sudo` | Aplica la configuración del host al LXC vía remoto (SSH)[^**]            |
| `nixos-rebuild switch --flake .#<host>`                                          | Aplica la configuración del host a la máquina actual                     |

[^*] Ya no es necesario ya que puedo aplicar la config al LXC vía SSH.

[^**] Obviamente, es MANDATORY haber añadido las claves SSH previamente en el
`configuration.nix`, por comodidad.

> [!CAUTION] CUIDADO CON APLICAR LA CONFIG DE UN HOST EN LA MÁQUINA EQUIVOCADA
>
> `nixos-rebuild` recompila la configuración del sistema con lo que se describe
> en el `configuration.nix` del host seleccionado. Al usar un host distinto al
> original puede ocurrir que se apliquen configuraciones incompatibles con el
> sistema y hardware actuales, además de romper las credenciales del login al
> cambiarse el hostname sin asignar una nueva contraseña.

> [!NOTE]+ `nixos-rebuild build-image --image-variant lxc --flake .#<host>`
>
> Esto genera un softlink `result/` al directorio de la store de NixOS donde se
> encuentra la imagen LXC en formato `tar.gz`. Sin embargo, aunque el LXC tiene
> aplicada la configuración, no incluye los ficheros de configuración dentro de
> la carpeta del sistema de NixOS, lo que va a provocar que siempre que se
> inicie el contenedor, utilice la configuración con la que fue generada la
> imagen, aún con `nixos-rebuild switch`.
