{ config, lib, ... }:
let
  cfg = config.homeconfig.gui;
in
{
  config = lib.mkIf (cfg.enable && cfg.catppuccin.enable) {
    catppuccin = {
      enable = true;
      autoEnable = false;
      flavor = "mocha";
      accent = "blue";
    };
  };
}
