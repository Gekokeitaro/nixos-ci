{ pkgs, ... }:
{
  services.dbus.implementation = "dbus";
  boot.isContainer = true;

  # Stack gráfico base (Mesa, libdrm). Los drivers específicos (Vulkan/ROCm)
  # se añaden en cada host según el perfil.
  hardware.graphics.enable = true;

  systemd.suppressedSystemUnits = [
    "dev-mqueue.mount"
    "sys-kernel-debug.mount"
    "sys-fs-fuse-connections.mount"
  ];

  # Clona nixos-ci vía http en /home/nixos-ci al arrancar.
  #
  # ConditionPathExists = "!<path>" → si el path YA existe, systemd se salta
  #   el servicio entero (no cuenta como fallo, no re-clona, no toca nada).
  #   Es lo que hace esto idempotente: seguro en cada rebuild/reboot, no solo
  #   la primera vez. Si algún día quieres forzar un re-clone, borra a mano
  #   la carpeta en el LXC y el próximo boot vuelve a clonar.
  #
  # Type = oneshot → arranca, hace su trabajo, termina; no es un daemon.
  systemd.services.clone-nixos-ci-repo = {
    description = "Clone nixos-ci repo into /home/nixos-ci if not exists";
    wantedBy = ["multi-user.target"];
    after = ["network-online.target"];
    wants = ["network-online.target"];
    unitConfig.ConditionPathExists = "!/home/nixos-ci";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.git}/bin/git clone https://github.com/Gekokeitaro/nixos-ci.git /home/nixos-ci";
    };
  };

  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
    settings.KbdInteractiveAuthentication = false;
    settings.PermitRootLogin = "no";
  };

  security.sudo.wheelNeedsPassword = false;

  nix.gc = {
    automatic = true;
    options = "--delete-older-than 3d";
  };

  # /sbin/init en imágenes LXC construidas con nixos-rebuild build-image es un
  # fichero estático copiado del store original. Proxmox lo ejecuta en cada
  # arranque, lo que provoca que el sistema vuelva siempre a la generación
  # inicial ignorando cualquier nixos-rebuild switch posterior.
  #
  # Este activation script lo reemplaza por un symlink al perfil activo
  # (/nix/var/nix/profiles/system/init) en cada nixos-rebuild switch, de modo
  # que el próximo arranque use la generación correcta.
  system.activationScripts.updateSbinInit = ''
    rm -f /sbin/init
    ln -sfn /nix/var/nix/profiles/system/init /sbin/init
  '';
}
