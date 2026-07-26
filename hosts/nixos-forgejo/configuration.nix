{pkgs, ...}: {
  imports = [
    ../../common
  ];

  users.users.nixos-forgejo = {
    isNormalUser = true;

    extraGroups = ["wheel"];

    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGApUnvphJshC3LJ4QxDu8fm3JqEnSWZ6ewhf6gQuF7V PopOS OCT 2024"
    ];

    packages = with pkgs; [
      tree
      git
      curl
      wget
      magic-wormhole
    ];
  };

  services.forgejo = {
    enable = true;
    database.type = "sqlite3";
    # `true` para habilitar temporalmente la creación de cuentas de usuario, `false` para deshabilitarla y `nil` para usar la configuración por defecto.
    service.DISABLE_REGISTRATION = true;

    # Soporte para actions, basado en act: https://github.com/nektos/act
    actions = {
      ENABLED = true;
      DEFAULT_ACTIONS_URL = "github";
    };
  };

  nix.settings.experimental-features = ["nix-command" "flakes"];

  system.stateVersion = "26.05";
}
