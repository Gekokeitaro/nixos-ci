# NixOS LXC

Plantilla para crear LXC de NixOS, utilizando de base:
- https://gysli.ng/posts/tech/proxmox-nixos/
 

# Comandos

- `nix flake show .` - Muestra información sobre la flake.
- `nix run .#update-llama-cpp` - Actualiza llama.cpp a la última versión disponible en GitHub.
- `nixos-rebuild build-image --image-variant lxc --flake .#<host>` - Genera la imagen LXC.
- `nixos-rebuild switch --flake .#<host>` - Aplica la configuración a la máquina.

## Configuración básica

- Editar <host> y la ssh key para acceso por SSH.

## build-image --image-variant lxc

- El resultado es un softlink apuntando al `tar.gz` de la imagen en `store`
- Nada más iniciar el contenedor, lanzar `nix-channel --update`
- Los ficheros de configuración (`flake.nix`, `configuration.nix`...) no viajan a la imagen del contenedor, para mantener la config y hacer cambios, clona el repo dentro del contenedor.

# Actualizar llama.cpp automáticamente

Para actualizar `llama.cpp` a la última versión estable lanzada en GitHub y recalcular su hash de forma automática, ejecuta:

```bash
nix run .#update-llama-cpp
```

## Método manual (alternativo)

Si prefieres obtener el hash y actualizar el archivo
`packages/llama-cpp/default.nix` manualmente:

```bash
nix shell nixpkgs#nix-prefetch-github nixpkgs#jq nixpkgs#curl

# Obtener latest release
LATEST=$(curl -sf https://api.github.com/repos/ggml-org/llama.cpp/releases/latest | jq -r '.tag_name')
echo "Latest: $LATEST"

# Obtener hash SRI para fetchFromGitHub
nix-prefetch-github ggml-org llama.cpp --rev "$LATEST"
# → { "hash": "sha256-XXXX=", "rev": "bNNNN" }
```

# Passthrough de iGPU AMD a LXC Unprivileged en Proxmox 9

Para usar la iGPU/GPU de AMD desde un LXC en Proxmox 9 (o más reciente):

## 1. Identificar el GID del grupo `render` en el LXC NixOS

Inicia el contenedor y obtén el identificador de grupo (GID) de `render` y `video` (para ROCm):

```bash
getent group render | cut -d: -f3
getent group video | cut -d: -f3
# → Ej: 303, 26
```

## 2. Configurar el Passthrough en Proxmox

1. Ve a tu contenedor LXC -> **Resources** -> **Add** -> **Device Passthrough**.
2. Configura los siguientes campos:
   - **Device Path**: `/dev/dri/renderD128`
   - **Mode**: `0666`
   - Marca **Advanced** y pon el **GID** obtenido en el paso 1 (ej: `108`), con
     **UID** `0`.
3. Repite el proceso para `/dev/dri/card0` y `/dev/kfd` (para ROCm) si es necesario.

Reinicia el contenedor LXC desde Proxmox tras aplicar los cambios.

## 3. Verificar desde el LXC NixOS

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

## 4. GPU job timeout

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
