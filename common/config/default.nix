{pkgs, ...}: {
  services.dbus.implementation = "dbus";
  boot.isContainer = true;

  # Base graphics stack (Mesa, libdrm). The specific drivers (Vulkan/ROCm)
  # are added per host, according to the profile.
  hardware.graphics.enable = true;

  # https://gysli.ng/posts/tech/proxmox-nixos/
  # Disable the systemd units that do not work inside LXC containers.
  systemd.suppressedSystemUnits = [
    "dev-mqueue.mount"
    "sys-kernel-debug.mount"
    "sys-fs-fuse-connections.mount"
  ];

  # Enable openSSH so the container can be reached.
  # Public-key access only (no password). Root login is forbidden.
  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
    settings.KbdInteractiveAuthentication = false;
    settings.PermitRootLogin = "no";
  };

  # Passwordless sudo for users in the wheel group.
  security.sudo.wheelNeedsPassword = false;

  # Automatic garbage collection every 3 days.
  nix.gc = {
    automatic = true;
    options = "--delete-older-than 3d";
  };

  # Keep the deployed configuration across reboots
  system.activationScripts.proxmoxLxcInit = ''
    ln -sfn /nix/var/nix/profiles/system/init /sbin/init
  '';
}
