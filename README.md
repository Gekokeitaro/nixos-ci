# NixOS LXC

Repo para crear, desplegar y actualizar los LXC de mi homelab.

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

actualiza la configuración del LXC. ES MANDATORY QUE EL LXC TENGA CARGADA LA
CLAVE PUBLICA DE nixos-ci EN `configuration.nix` -> Actualiza la configuración
del LXC con la definida en el host.

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

## Configuración común

- Todos los LXC tienen por defecto NVF (Neovim) para hacer pequeñas
  modificaciones con vistas a testing.

## Passthrough de iGPU AMD a LXC Unprivileged en Proxmox 9

Para usar la iGPU/GPU de AMD desde un LXC en Proxmox 9 (o más reciente):

### 1. Identificar el GID del grupo `render` en el LXC NixOS

Inicia el contenedor y obtén el identificador de grupo (GID) de `render` y
`video` (para ROCm):

```bash
getent group render | cut -d: -f3
getent group video | cut -d: -f3
# → Ej: 303, 26
```

### 2. Configurar el Passthrough en Proxmox

1. Ve a tu contenedor LXC -> **Resources** -> **Add** -> **Device Passthrough**.
2. Configura los siguientes campos:
   - **Device Path**: `/dev/dri/renderD128`
   - **Mode**: `0666`
   - Marca **Advanced** y pon el **GID** obtenido en el paso 1 (ej: `108`), con
     **UID** `0`.
3. Repite el proceso para `/dev/dri/card0` y `/dev/kfd` (para ROCm) si es
   necesario.

Reinicia el contenedor LXC desde Proxmox tras aplicar los cambios.

### 3. Verificar desde el LXC NixOS

Comprueba que los dispositivos se listan y tienen permisos adecuados:

```bash
ls -l /dev/dri
# Debe mostrar renderD128 y card0 accesibles por el grupo render.
```

Ejecuta el diagnóstico según el perfil (Vulkan o ROCm) usando Nix Shell:

```bash
# Para el perfil Vulkan (RADV)
nix shell nixpkgs#vulkan-tools -c vulkaninfo --summary

# Para el perfil ROCm
nix shell nixpkgs#rocmPackages.rocminfo -c rocminfo
```

### 4. GPU job timeout

-> https://github.com/ggml-org/llama.cpp/issues/21724

> [!QUOTE] 'The default Linux amdgpu.lockup_timeout is 2000ms.
> ggml_backend_vk_graph_compute batches up to 100 nodes per vkQueueSubmit. On
> slow integrated GPUs/APUs, the accumulated GPU work in a single submission
> exceeds this timeout, causing the kernel to reset the compute ring.'

Estaba teniendo este mismo problema al utilizar Lightrag. Aún no hay fix
oficial, así que la solución pasa por aumentar el `lockup_timeout`. Puede tener
side-effects ya que el timeout se utiliza para evitar posibles cuelgues. En
Proxmox 9.1.:

> [!NOTE]
>
> 1. echo "options amdgpu lockup_timeout=30000" > /etc/modprobe.d/amdgpu.conf
> 2. update-initramfs -u -k all && reboot

Necesita ajustes, pero es un workaround que funciona.
