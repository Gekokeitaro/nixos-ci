# nixos-forgejo: aloja Forgejo, una forja Git auto-hospedada.
# Forgejo es un fork comunitario de Gitea orientado a la privacidad.
# Docs oficiales: https://forgejo.org/docs/latest/
# Módulo NixOS: https://search.nixos.org/options?query=services.forgejo
#
# Base de datos: SQLite (sin servidor externo, suficiente para uso personal).
# Dashboard HTTP accesible en el puerto 3000 del contenedor.
#
# Primer arranque:
#   1. Despliega la imagen LXC en Proxmox.
#   2. Accede a http://<ip-lxc>:3000 → asistente de configuración inicial.
#   3. Crea el usuario administrador desde la UI.
#   4. Cuando ya no se necesite registro abierto, cambia
#      services.forgejo.settings.service.DISABLE_REGISTRATION a true
#      y aplica: nixos-rebuild switch --flake .#nixos-forgejo
#
# Acciones (CI/CD) no activadas en esta primera versión; se pueden
# habilitar añadiendo settings.actions.ENABLED = true cuando haya
# un runner configurado.
{pkgs, ...}: {
  imports = [
    ../../common # base LXC: openssh, sudo, gc automático, boot.isContainer…
  ];

  networking.hostName = "nixos-forgejo";

  # Usuario de mantenimiento. Solo se usa para SSH y tareas admin.
  # El servicio Forgejo corre bajo su propio usuario de sistema (`forgejo`),
  # creado automáticamente por el módulo NixOS.
  users.users.nixos-forgejo = {
    isNormalUser = true;
    extraGroups = ["wheel"]; # sudo sin contraseña (ver common: wheelNeedsPassword = false)

    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGApUnvphJshC3LJ4QxDu8fm3JqEnSWZ6ewhf6gQuF7V PopOS OCT 2024"
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

  services.forgejo = {
    enable = true;

    # SQLite no requiere ningún servidor de base de datos adicional.
    # Para producción con alta carga habría que migrar a PostgreSQL, pero
    # para uso personal con pocos repositorios es perfectamente viable.
    database.type = "sqlite3";

    # Configuración de la aplicación (equivale a app.ini de Gitea/Forgejo).
    # Referencia completa de opciones: https://forgejo.org/docs/latest/admin/config-cheat-sheet/
    settings = {
      # false → el registro está abierto; cualquiera puede crear cuenta.
      # Poner a true una vez creado el admin para cerrar el registro público.
      service.DISABLE_REGISTRATION = false;

      server = {
        # Puerto donde escucha el servidor HTTP interno de Forgejo.
        # Nginx u otro proxy inverso puede reenviar aquí si se quiere HTTPS.
        HTTP_PORT = 3000;

        # Dominio que Forgejo usa para construir URLs absolutas (clones, emails…).
        # Con "localhost" solo funciona desde el propio contenedor; cambiar a la
        # IP o FQDN real del LXC cuando se configure un dominio permanente.
        DOMAIN = "0.0.0.0";

        # URL raíz que aparece en los enlaces de la interfaz y en los hooks.
        # Debe coincidir con DOMAIN. Si se añade un proxy inverso con HTTPS,
        # cambiar a https://<dominio>/.
        ROOT_URL = "http://0.0.0.0:3000/";
      };
    };
  };

  # Abre el puerto del dashboard en el firewall interno del LXC.
  # En Proxmox el tráfico entre la red del host y el LXC pasa por la
  # interfaz de red virtual; sin esta regla el paquete se descartaría
  # antes de llegar al proceso Forgejo.
  networking.firewall.allowedTCPPorts = [3000];

  # Habilita los comandos `nix` y `nixos-rebuild --flake` dentro del LXC,
  # necesarios para aplicar cambios de configuración desde el propio contenedor.
  nix.settings.experimental-features = ["nix-command" "flakes"];

  system.stateVersion = "26.05";
}
