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
        Enable GUI environment. Implicitly enables nixconfig.gui.fonts and
        nixconfig._1password via mkDefault. Desktop environment (gnome/kde)
        must be explicitly enabled per host.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # Fonts and 1Password enabled by default when GUI is enabled.
    # Desktop environment (nixconfig.gnome / nixconfig.kde) must be set explicitly per host.
    nixconfig = {
      gui.fonts.enable = lib.mkDefault true;
      _1password.enable = lib.mkDefault true;
    };
  };
}
