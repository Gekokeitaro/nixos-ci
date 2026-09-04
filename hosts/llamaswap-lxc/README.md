> [!summary] LXC que levanta una instancia de llama.cpp gestionada por
> llama-swap para inferencia con modelso locales.
>
> El package de llama.cpp es el oficial de nix, pero tuneado para poder compilar
> las última versiones utilizando el backend de Vulkan o ROCm.
>
> Para actualizar la versión de llama.cpp y el hash hay un script que se puede
> lanzar con `nix run .#update-llama-cpp`, aunque no está actualizado para traer
> también el hash de la WebUI, tengo que ver si puedo quitarla o en caso
> contrario automatizar la actualización de su hash.

- https://llama.app
- ttps://github.com/mostlygeek/llama-swap

## Configuración en Proxmox

### Passthrough de iGPU AMD a LXC Unprivileged en Proxmox 9

Para usar la iGPU/GPU de AMD desde un LXC en Proxmox 9 (o más reciente):

#### 1. Identificar el GID del grupo `render` en el LXC NixOS

Inicia el contenedor y obtén el identificador de grupo (GID) de `render` y
`video` (para ROCm):

```bash
getent group render | cut -d: -f3
getent group video | cut -d: -f3
# → Ej: 303, 26
```

#### 2. Configurar el Passthrough en Proxmox

1. Ve a tu contenedor LXC -> **Resources** -> **Add** -> **Device Passthrough**.
2. Configura los siguientes campos:
   - **Device Path**: `/dev/dri/renderD128`
   - **Mode**: `0666`
   - Marca **Advanced** y pon el **GID** obtenido en el paso 1 (ej: `108`), con
     **UID** `0`.
3. Repite el proceso para `/dev/dri/card0` y `/dev/kfd` (para ROCm) si es
   necesario.

Reinicia el contenedor LXC desde Proxmox tras aplicar los cambios.

#### 3. Verificar desde el LXC NixOS

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

#### 4. GPU job timeout

En CPU poco potentes o no orientadas a IA (como es mi caso), puede pasar que las
operaciones de inferencia sobrepasen el tiempo que determinan los sistemas UNIX
para comprobar que la GPU funciona correctamente. Normalmente son 2000ms, y si
la GPU sigue procesando para entonces, Linux simplemente reinicia los drivers
cortando la operación y devolviendo un error.

Aunque es un arma de doble filo, la solución pasa por aumentar el timeout, con
la desventaja de que en caso de error real de la GPU se tardaría más en
detectarlo.

> [!QUOTE] 'The default Linux amdgpu.lockup_timeout is 2000ms.
> ggml_backend_vk_graph_compute batches up to 100 nodes per vkQueueSubmit. On
> slow integrated GPUs/APUs, the accumulated GPU work in a single submission
> exceeds this timeout, causing the kernel to reset the compute ring.' -
> https://github.com/ggml-org/llama.cpp/issues/21724

> [!NOTE] Solución aplicada:
>
> 1. echo "options amdgpu lockup_timeout=30000" > /etc/modprobe.d/amdgpu.conf
> 2. update-initramfs -u -k all && reboot

Necesita ajustes, pero es un workaround que funciona.
