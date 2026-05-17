{ config, lib, ... }:
let
  cfg = config.homeconfig.gui;
in
{
  config = lib.mkIf (cfg.enable && cfg.plasma.enable) {
    programs.plasma = {
      enable = true;

      workspace = {
        # Wayland is default; Plasma 6 looks good dark
        lookAndFeel = "org.kde.breezedark.desktop";
      };
    };
  };
}
