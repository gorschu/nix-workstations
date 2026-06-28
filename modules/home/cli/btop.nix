{ config, lib, ... }:
let
  cfg = config.homeconfig.cli;
in
{
  config = lib.mkIf (cfg.enable && cfg.system.enable) {
    catppuccin.btop.enable = true;

    programs.btop.enable = true;
  };
}
