> [!NOTE] Rama de desarrollo para el LXC de llamaswap con backend Vulkan.

Aquí sólo estarán las configuraciones y modelos que se haya comprobado que funcionan de manera estable y mejor que en ROCm.

## Comandos

- `nix flake show .` - Muestra información sobre la flake.
- `sudo nixos-rebuild switch --flake .#nixos-llamaswap-vulkan`.
- `nix run .#update-llama-cpp` - Sube la versión de llama-cpp a la última del repo.
  - La sincronización del hash de la WebUI no está implementada, por lo que si cambia habrá que copiarla desde el error que aparecerá cuando se haga `nixos-rebuild`.
- `ls -lut /nix/store/ | grep llama-cpp` - Muestra los últimos paquetes de llama-cpp compilados.
  - En la carpeta `bin` se encuentra `llama-bench` para poder hacer las pruebas de rendimiento y configuración.
  - `llama-bench -h`
- `sudo journalctl -u llama-swap.service --no-pager -n 200` - Debug de llamaswap