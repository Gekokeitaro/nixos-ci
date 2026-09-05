# nixos-n8n: aloja n8n, plataforma de automatización de workflows.
# n8n permite conectar servicios y APIs mediante flujos visuales.
# Docs oficiales: https://docs.n8n.io/
# Módulo NixOS: https://search.nixos.org/options?query=services.n8n
#
# Base de datos: SQLite (por defecto en n8n, suficiente para uso personal).
# Dashboard HTTP accesible en el puerto 5678 del contenedor.
#
# Primer arranque:
#   1. Despliega la imagen LXC en Proxmox.
#   2. Accede a http://<ip-lxc>:5678 → asistente de configuración inicial.
#   3. Crea el usuario administrador desde la UI.
#   4. Para producción con alta carga, migrar a PostgreSQL vía variables de entorno.
{pkgs, ...}: {
  imports = [
    ../../common # base LXC: openssh, sudo, gc automático, boot.isContainer…
  ];

  networking.hostName = "nixos-n8n";

  # Usuario de mantenimiento. Solo se usa para SSH y tareas admin.
  # El servicio n8n corre bajo su propio usuario de sistema (`n8n`),
  # creado automáticamente por el módulo NixOS.
  users.users.nixos-n8n = {
    isNormalUser = true;
    extraGroups = ["wheel"]; # sudo sin contraseña (ver common: wheelNeedsPassword = false)

    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGApUnvphJshC3LJ4QxDu8fm3JqEnSWZ6ewhf6gQuF7V PopOS OCT 2024"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFeASXjLf7TjNTxO5CZ4Aa6z8hyFG0CXAe4FhcpZOEp6 NixOS-CI MAY 2026"
    ];
  };

  # Herramientas CLI disponibles para todos los usuarios del sistema.
  # NOTA: users.users.<name>.packages no existe en módulos NixOS puros
  # (solo en home-manager); los paquetes van siempre aquí.
  environment.systemPackages = with pkgs; [
    tree
    git
    curl
    wget
    magic-wormhole # transferencia rápida de ficheros entre máquinas sin servidor intermedio
  ];

  services.n8n = {
    enable = true;

    # Puerto donde escucha el servidor HTTP interno de n8n.
    # Nginx u otro proxy inverso puede reenviar aquí si se quiere HTTPS.
    port = 5678;

    # Escucha en todas las interfaces para acceso externo desde la red Proxmox.
    host = "0.0.0.0";

    # Abre el puerto en el firewall interno del LXC.
    openFirewall = true;
  };

  # Usuario trusted para nix: puede ejecutar comandos nix sin restricciones
  # y modificar la configuración del sistema.
  nix.settings.trusted-users = ["nixos-n8n"];

  nix.settings.experimental-features = ["nix-command" "flakes"];

  system.stateVersion = "26.05";
}
