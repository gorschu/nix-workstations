{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.homeconfig.cli;
in
{
  config = lib.mkIf (cfg.enable && cfg.shell.enable) {
    catppuccin = {
      bat.enable = true;
      eza.enable = true;
    };

    programs = {
      bat = {
        enable = true;
        config = {
          style = "auto";
          italic-text = "always";
        };
        extraPackages = with pkgs.bat-extras; [
          batdiff
          batgrep
          batman
          batpipe
          batwatch
          prettybat
        ];
      };

      eza = {
        enable = true;
        enableZshIntegration = true;
        colors = "auto";
        git = true;
        icons = "auto";
        extraOptions = [
          "--group-directories-first"
          "--header"
          "--group"
          "--hyperlink"
        ];
      };

      fd = {
        enable = true;
        ignores = [
          "containers"
        ];
      };
    };

    home.sessionVariables.EZA_ICON_SPACING = "2";
    home.sessionVariables.PAGER = "bat";
  };
}
