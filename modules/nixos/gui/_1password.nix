{
  config,
  lib,
  ...
}:
let
  cfg = config.nixconfig._1password;
in
{
  options.nixconfig._1password = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable 1Password GUI and CLI with system integration";
    };
  };

  config = lib.mkIf cfg.enable {
    # 1Password GUI application
    programs._1password-gui = {
      enable = true;
      polkitPolicyOwners = config.myusers;
    };

    # 1Password CLI
    programs._1password = {
      enable = true;
    };

    # Enable browser integration
    environment.etc."1password/custom_allowed_browsers".text = ''
      firefox
      chromium
      google-chrome
      brave
      vivaldi
    '';
  };
}
