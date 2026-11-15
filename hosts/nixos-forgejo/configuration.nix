# nixos-forgejo: hosts Forgejo, a self-hosted Git forge.
# Forgejo is a community fork of Gitea focused on privacy.
# Official docs: https://forgejo.org/docs/latest/
# NixOS module: https://search.nixos.org/options?query=services.forgejo
#
# Database: SQLite (no external server, enough for personal use).
# HTTP dashboard reachable on port 3000 of the container.
#
# First boot:
#   1. Deploy the LXC image on Proxmox.
#   2. Open http://<lxc-ip>:3000 → first-run configuration wizard.
#   3. Create the administrator user from the UI.
#   4. Once open registration is no longer needed, change
#      services.forgejo.settings.service.DISABLE_REGISTRATION to true
#      and apply: nixos-rebuild switch --flake .#nixos-forgejo
#
# Actions (CI/CD) are not enabled in this first version; they can be
# enabled by adding settings.actions.ENABLED = true once there is
# a configured runner.
{
  pkgs,
  config,
  ...
}: {
  imports = [
    ../../common # LXC base: openssh, sudo, automatic gc, boot.isContainer…
  ];

  networking.hostName = "nixos-forgejo";

  # Maintenance user. Only used for SSH and admin tasks.
  # The Forgejo service runs under its own system user (`forgejo`),
  # created automatically by the NixOS module.
  users.users.nixos-forgejo = {
    isNormalUser = true;
    extraGroups = ["wheel"]; # passwordless sudo (see common: wheelNeedsPassword = false)

    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGApUnvphJshC3LJ4QxDu8fm3JqEnSWZ6ewhf6gQuF7V PopOS OCT 2024"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFeASXjLf7TjNTxO5CZ4Aa6z8hyFG0CXAe4FhcpZOEp6 NixOS-CI MAY 2026"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOItHReLpLr0DZHohVHBdqu7CePpsuQ3ANa0UsUX0xj+ pablo.bugarin.camara@gmail.com"
    ];
  };

  # CLI tools available to every user of the system.
  # NOTE: users.users.<name>.packages does not exist in pure NixOS
  # modules (only in home-manager); packages always go here.
  environment.systemPackages = with pkgs; [
    tree
    git
    curl
    wget
    magic-wormhole # fast file transfer between machines without an intermediate server
    (pkgs.writeShellScriptBin "forgejo-admin" ''
      exec sudo -u ${config.services.forgejo.user} \
      ${config.services.forgejo.package}/bin/forgejo \
      --work-path ${config.services.forgejo.stateDir} "$@"
    '')
  ];

  services.forgejo = {
    enable = true;

    # SQLite needs no additional database server.
    # Production with a heavy load would have to migrate to PostgreSQL, but
    # for personal use with a few repositories it is perfectly viable.
    database.type = "sqlite3";

    # Application configuration (equivalent to Gitea/Forgejo's app.ini).
    # Full option reference: https://forgejo.org/docs/latest/admin/config-cheat-sheet/
    settings = {
      # false → registration is open; anyone can create an account.
      # Set to true once the admin exists, to close public registration.
      service.DISABLE_REGISTRATION = true;
      actions.ENABLED = true;

      server = {
        # Port the internal Forgejo HTTP server listens on.
        # Nginx or another reverse proxy can forward here if HTTPS is wanted.
        HTTP_PORT = 3000;

        # Domain Forgejo uses to build absolute URLs (clones, emails…).
        # With "localhost" it only works from inside the container; change to
        # the real IP or FQDN of the LXC when a permanent domain is configured.
        DOMAIN = "192.168.18.31";

        # Root URL that appears in interface links and hooks.
        # Must match DOMAIN. If a reverse proxy with HTTPS is added,
        # change to https://<domain>/.
        ROOT_URL = "http://192.168.18.31:3000/";
      };
    };
  };

  # Open the dashboard port in the LXC's internal firewall.
  # On Proxmox the traffic between the host network and the LXC goes through
  # the virtual network interface; without this rule the packet would be dropped
  # before reaching the Forgejo process.
  networking.firewall.allowedTCPPorts = [3000];

  nix.settings.trusted-users = ["nixos-forgejo"];

  # Enable the `nix` and `nixos-rebuild --flake` commands inside the LXC,
  # required to apply configuration changes from the container itself.
  nix.settings.experimental-features = ["nix-command" "flakes"];

  system.stateVersion = "26.05";
}
