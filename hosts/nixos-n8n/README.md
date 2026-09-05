# nixos-n8n

Host NixOS para n8n — plataforma de automatización de workflows tipo "no-code/low-code".

## Qué incluye

- **n8n** como servicio systemd nativo (módulo NixOS `services.n8n`)
- **SQLite** como base de datos (por defecto, sin dependencias externas)
- **Firewall** abierto en puerto 5678
- **Usuario de mantenimiento** `nixos-n8n` con sudo (grupo `wheel`)
- **Trusted user** de Nix: `nixos-n8n` puede ejecutar `nix`/`nixos-rebuild`
- **Neovim** (nvf) y herramientas CLI: `tree`, `git`, `curl`, `wget`, `magic-wormhole`

## Build de la imagen LXC

```bash
nixos-rebuild build-image --image-variant lxc --flake .#nixos-n8n
```

El resultado es un symlink `result` → tarball `.tar.gz` en el Nix store.
Importar directamente en Proxmox como plantilla LXC.

## Primer arranque

1. Despliega la plantilla LXC en Proxmox (recursos sugeridos: 2 CPU, 2-4 GB RAM, 20 GB disco).
2. Arranca el contenedor.
3. Accede a `http://<IP-LXC>:5678` — asistente de configuración inicial de n8n.
4. Crea usuario administrador desde la UI.
5. (Opcional) Para cerrar registro público, edita la configuración y vuelve a aplicar:
   ```bash
   nixos-rebuild switch --flake .#nixos-n8n
   ```

## Configuración de base de datos

Por defecto usa **SQLite** (archivo en `/var/lib/n8n/database.sqlite`). Para producción con alta carga:

```nix
services.n8n = {
  enable = true;
  # ...
  extraConfig = ''
    DB_TYPE=postgresdb
    DB_POSTGRESDB_HOST=...
    DB_POSTGRESDB_PORT=5432
    DB_POSTGRESDB_DATABASE=n8n
    DB_POSTGRESDB_USER=n8n
    DB_POSTGRESDB_PASSWORD=...
  '';
};
```

## Acceso SSH

```bash
ssh nixos-n8n@<IP-LXC>
```

Clave autorizada: la misma que `nixos-ci` (PopOS OCT 2024).

## Aplicar cambios de configuración

Desde dentro del LXC (tras `nix-channel --update`):

```bash
sudo nixos-rebuild switch --flake .#nixos-n8n
```

El script de activación `updateSbinInit` (en `common/`) actualiza `/sbin/init` para que los cambios persistan tras reboot.

## Firewall

El puerto 5678 está abierto en el firewall interno del LXC (`networking.firewall.allowedTCPPorts`).
En Proxmox el tráfico entre host y LXC pasa por la interfaz virtual; si hay firewall adicional en el host Proxmox, permitir el puerto 5678.

## Notas

- Contenedor **unprivileged** (no usar configuración que requiera privilegios).
- `boot.isContainer = true` — sin bootloader ni configuración de hardware.
- `nixpkgs` sigue canal `nixos-unstable`.
- Para migración a PostgreSQL, añadir servicio `services.postgresql` y variables de entorno en `extraConfig`.