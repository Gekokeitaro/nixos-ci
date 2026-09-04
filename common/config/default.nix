{ pkgs, ... }:
{
  services.dbus.implementation = "dbus";
  boot.isContainer = true;

  # Stack gráfico base (Mesa, libdrm). Los drivers específicos (Vulkan/ROCm)
  # se añaden en cada host según el perfil.
  hardware.graphics.enable = true;


  # https://gysli.ng/posts/tech/proxmox-nixos/
  # Desactivamos unidades de systemd que no funcionan en contenedores LXC.
  systemd.suppressedSystemUnits = [
    "dev-mqueue.mount"
    "sys-kernel-debug.mount"
    "sys-fs-fuse-connections.mount"
  ];

  # Habilitamos openSSH para poder entrar al contenedor.
  # Acceso por clave pública (sin contraseña). Prohibido el acceso root.
  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
    settings.KbdInteractiveAuthentication = false;
    settings.PermitRootLogin = "no";
  };

  # Sudo sin contraseña para usuarios del grupo wheel.
  security.sudo.wheelNeedsPassword = false;

  # Garbage collection automático cada 3 días.
  nix.gc = {
    automatic = true;
    options = "--delete-older-than 3d";
  };
}
