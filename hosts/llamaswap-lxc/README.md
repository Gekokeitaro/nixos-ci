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

# Actualizar llama.cpp automáticamente

Para actualizar `llama.cpp` a la última versión estable lanzada en GitHub y recalcular su hash de forma automática, ejecuta:

```bash
nix run .#update-llama-cpp
```

## Método manual (alternativo)

Si prefieres obtener el hash y actualizar el archivo `packages/llama-cpp/default.nix` manualmente:

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

Para usar la iGPU (AMD 680M) dentro del LXC no privilegiado en Proxmox VE 9, sigue estos pasos:

## 1. Identificar el GID del grupo `render` en el LXC NixOS
Inicia el contenedor y obtén el identificador de grupo (GID) de `render`:
```bash
getent group render | cut -d: -f3
# → Ej: 108
```

## 2. Configurar el Passthrough en Proxmox

### Método A: Desde la interfaz Web de Proxmox (Recomendado)
1. Ve a tu contenedor LXC -> **Resources** -> **Add** -> **Device Passthrough**.
2. Configura los siguientes campos:
   - **Device Path**: `/dev/dri/renderD128`
   - **Mode**: `0666`
   - Marca **Advanced** y pon el **GID** obtenido en el paso 1 (ej: `108`), con **UID** `0`.
3. Repite el proceso para `/dev/dri/card0` si es necesario.

### Método B: Desde el archivo de configuración en el host Proxmox (CLI)
Edita el archivo `/etc/pve/lxc/<CTID>.conf` en Proxmox y añade las siguientes líneas al final (ajustando el `gid` al valor obtenido en el paso 1):

```text
dev0: path=/dev/dri/renderD128,gid=108,uid=0,mode=0666
dev1: path=/dev/dri/card0,gid=108,uid=0,mode=0666
```

> [!NOTE]
> Si prefieres el método tradicional basado en cgroups y bind mounts, puedes añadir en su lugar:
> ```text
> lxc.cgroup2.devices.allow: c 226:* rwm
> lxc.mount.entry: /dev/dri dev/dri none bind,optional,create=dir
> ```

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

