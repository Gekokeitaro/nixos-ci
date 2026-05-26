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

  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
    settings.KbdInteractiveAuthentication = false;
    settings.PermitRootLogin = "no";
  };

  security.sudo.wheelNeedsPassword = false;
}
