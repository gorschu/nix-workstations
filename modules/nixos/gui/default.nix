{ config, lib, ... }:
let
  inherit (builtins) readDir attrNames filter;
  cfg = config.nixconfig.gui;
in
{
  # Always import GUI modules (they have their own enable guards)
  imports = map (fn: ./${fn}) (filter (fn: fn != "default.nix") (attrNames (readDir ./.)));

  options.nixconfig.gui = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Enable GUI environment. Implicitly enables nixconfig.gnome, nixconfig.gui.fonts,
        and nixconfig._1password via mkDefault. Override any of them with = false.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # GNOME, fonts, and 1Password enabled by default when GUI is enabled
    nixconfig = {
      gnome.enable = lib.mkDefault true;
      gui.fonts.enable = lib.mkDefault true;
      _1password.enable = lib.mkDefault true;
    };
  };
}
