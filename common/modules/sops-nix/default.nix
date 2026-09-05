{
  lib,
  config,
  inputs,
  ...
}:
with lib; let
  cfg = config.commonModules.sops;
in {
  imports = [inputs.sops-nix.nixosModules.sops];

  options.rootModules.sops = {
    enable = mkEnableOption "enable sops-nix root module";

    defaultSopsFile = mkOption {
      type = types.path;
      description = "Path to default sops file";
    };

    keyFile = mkOption {
      type = types.str;
      description = "Absolute path to the age key file";
    };

    secrets = mkOption {
      type = types.attrsOf types.attrs;
      default = {};
      description = "Secrets to declare for sops";
    };
  };

  config = mkIf cfg.enable {
    sops.defaultSopsFile = cfg.defaultSopsFile;
    sops.age.keyFile = cfg.keyFile;
    sops.secrets = cfg.secrets;
  };
}
