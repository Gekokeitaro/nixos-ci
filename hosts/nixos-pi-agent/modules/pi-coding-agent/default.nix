{
  config,
  lib,
  pkgs,
  ...
}: let
  user = "nixos-pi-agent";
  home = config.users.users.${user}.home;
  agentDir = "${home}/.pi/agent";
  cfg = config.piCodingAgent;
in {
  options.piCodingAgent = {
    enable = lib.mkEnableOption "pi-coding-agent";

    modelsPath = lib.mkOption {
      type = lib.types.path;
      default = ./config/models.json;
      description = "Path to models.json copied to ~/.pi/agent/models.json";
    };

    settingsPath = lib.mkOption {
      type = lib.types.path;
      default = ./config/settings.json;
      description = "Path to settings.json copied to ~/.pi/agent/settings.json";
    };

    extensions = lib.mkOption {
      type = lib.types.listOf lib.types.path;
      default = [];
      description = "Extension files symlinked to ~/.pi/agent/extensions/";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      (pkgs.symlinkJoin {
        name = "pi-coding-agent";
        paths = [pkgs.pi-coding-agent];
        nativeBuildInputs = [pkgs.makeWrapper];
        postBuild = ''
          wrapProgram $out/bin/pi \
            --prefix PATH : ${lib.makeBinPath [pkgs.nodejs pkgs.ripgrep pkgs.fd]} \
            --set NPM_CONFIG_PREFIX ${agentDir}/npm/ \
            --set-default PI_SKIP_VERSION_CHECK 1 \
            --set-default PI_TELEMETRY 0
        '';
      })
    ];

    systemd.tmpfiles.rules =
      [
        "d ${home}/.pi 0755 ${user} users -"
        "d ${agentDir} 0755 ${user} users -"
        "d ${agentDir}/npm 0755 ${user} users -"
        "d ${agentDir}/extensions 0755 ${user} users -"

        "L+ ${agentDir}/models.json - - - - ${cfg.modelsPath}"
        "C+ ${agentDir}/settings.json 0644 ${user} users - ${cfg.settingsPath}"
      ]
      ++ lib.map (ext: "L+ ${agentDir}/extensions/${lib.baseNameOf ext} - - - - ${ext}") cfg.extensions;

    systemd.services.pi-agent-sync = {
      wantedBy = ["multi-user.target"];
      after = ["systemd-tmpfiles-setup.service" "systemd-tmpfiles-resetup.service"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        User = user;
        Group = "users";
      };
      script = ''
        cp -f --no-preserve=mode,ownership ${cfg.settingsPath} ${agentDir}/settings.json
      '';
    };
  };
}
