{ config, lib, pkgs, ... }: let
  user = "nixos-pi-agent";
  home = config.users.user.${user}.home;
  agentDir = "${home}/.pi/agent";
  cfg = config.piCodingAgent;
in {
  options.piCodingAgent = {
    enable = lib.mkEnableOption "pi-coding-agent";

    extensions = lib.mkOption {
      type = lib.types.listOf lib.types.path;
      default = [ ];
      description = "Extension files symlinked to ~/.pi/agent/extensions/";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      (pkgs.symlinkJoin {
        name = "pi-coding-agent";
        paths = [ pkgs.pi-coding-agent ];
        nativeBuildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          wrapProgram $out/bin/pi \
            --prefix PATH : ${lib.makeBinPath [ pkgs.nodejs pkgs.ripgrep pkgs.fd ]} \
            --set NPM_CONFIG_PREFIX ${agentDir}/npm/ \
            --set-default PI_SKIP_VERSION_CHECK 1 \
            --set-default PI_TELEMETRY 0
        '';
      })
    ];

    systemd.tmpfiles.rules = [
      "d ${agentDir}/npm 0755 ${user} users -"
      "d ${agentDir}/extensions 0755 ${user} users -"
    ] ++ lib.map (ext: "L+ ${agentDir}/extensions/${lib.baseNameOf ext} - - - ${ext}") cfg.extensions;
  };
}
