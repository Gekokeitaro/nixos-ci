# NixOS LXC

Repo para crear, desplegar y actualizar los LXC de mi homelab.

## Hosts

- nixos-ci: Máquina de desarrollo, creación de imágenes LXC y actualización de
  contenedores.
- nixos-llamaswap-vulkan: llama.cpp + llamaswap para servir modelos locales.
  - También incluye Omniroute, aunque la idea será migrarlo a otro LXC.
- nixos-calibre-web-auto: Levanta
  [Calibre Web Automated](https://github.com/crocodilestick/Calibre-Web-Automated)
  para servir mis ebooks entre varios dispositivos.
- nixos-pihole: Abandonado. Nice to have pero ahora mismo no me sale a cuenta.
- (WIP) nixos-forgejo: Servidor para mantener mis repos y sincronizarlos con
  otros servicios, con CI/CD para los LXC.

## Comandos

- `nix flake show .` muestra los comandos y hosts del `flake.nix`
- `nixos-rebuild build-image --image-variant lxc --flake .#<host>` genera la
  imagen LXC del host. Se deprecará próximamente para aplicar las config
  directamente sobre una imagen mínima.
- `nixos-rebuild switch --flake .#<host> --target-host <user>@<ip> --elevate=sudo`
  actualiza la configuración del LXC. ES MANDATORY QUE EL LXC TENGA CARGADA LA
  CLAVE PUBLICA DE nixos-ci EN `configuration.nix` -> Actualiza la configuración
  del LXC
- `nixos-rebuild switch --flake .#<host>` - Recompila la configuración actual
  con la definida en el host.

> [!DANGER] CUIDADO CON APLICAR LA CONFIG DE UN HOST EN LA MÁQUINA EQUIVOCADA
>
> `nixos-rebuild` recompila la configuración del sistema con lo que se describe
> en el `configuration.nix` del host seleccionado. Al usar un host distinto al
> original puede ocurrir que se apliquen configuraciones incompatibles con el
> sistema y hardware actuales, además de romper las credenciales del login al
> cambiarse el hostname sin asignar una nueva contraseña.

## Configuración común

- Todos los LXC tienen por defecto NVF (Neovim) para hacer pequeñas
  modificaciones con vistas a testing.

> [!IMPORTANT] Ahora mismo, probablemente por ignorancia, los LXC vuelven a la
> configuración del sistema original cada vez que se reinician. Osea, ninguno de
> los cambios que se haga en `configuration.nix` se aplicará a menos que se haga
> `nixos-rebuild` cada vez que se levante el contenedor.
>
> Entonces, cualquier mejora se tiene que llevar al repo y regenerar la imagen.
>
> Para facilitar las pruebas, todos los LXC tienen descargado el repo por
> defecto dentro de /home/ (a falta de hacer que esté dentro de la carpeta del
> usuario en /home/)

- Todos los LXC son accesibles por SSH, cambiando la clave SSH.

# build-image --image-variant lxc

- El resultado es un softlink apuntando al `tar.gz` de la imagen en `store`
- Nada más iniciar el contenedor, lanzar `nix-channel --update`
- Los ficheros de configuración (`flake.nix`, `configuration.nix`...) no viajan
  a la imagen del contenedor, para mantener la config y hacer cambios, clona el
  repo dentro del contenedor.

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
