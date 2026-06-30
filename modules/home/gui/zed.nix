{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.homeconfig.gui;
in
{
  config = lib.mkIf (cfg.enable && cfg.zed.enable) {
    catppuccin.zed.enable = true;

    programs.zed-editor = {
      enable = true;
      package = pkgs.zed-editor;

      extensions = [
        "dockerfile"
        "just"
        "lua"
        "nix"
        "terraform"
      ];

      userSettings = {
        auto_update = false;
        buffer_font_family = "JetBrains Mono";
        load_direnv = "shell_hook";
        terminal.font_family = "Iosevka Term";
        telemetry.metrics = false;
        ui_font_family = "Adwaita Sans";
        vim_mode = true;
      };
    };
  };
}
