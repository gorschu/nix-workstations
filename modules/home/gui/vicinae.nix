{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.homeconfig.gui;
  hyprlandEnabled = config.wayland.windowManager.hyprland.enable;

  inherit (lib.generators) mkLuaInline;
  bind = key: dispatcher: {
    _args = [
      key
      (mkLuaInline dispatcher)
    ];
  };

  vicinaeBin = lib.getExe config.programs.vicinae.package;
  uwsmApp = lib.getExe' pkgs.uwsm "uwsm-app";
  uwsmHyprlandTarget = "wayland-session@hyprland.desktop.target";
in
{
  config = lib.mkMerge [
    (lib.mkIf (cfg.enable && cfg.vicinae.enable) {
      assertions = [
        {
          assertion = hyprlandEnabled;
          message = "homeconfig.gui.vicinae.enable requires Hyprland to be enabled.";
        }
      ];
    })

    (lib.mkIf (cfg.enable && cfg.vicinae.enable && hyprlandEnabled) {
      catppuccin.vicinae.enable = true;

      programs.vicinae = {
        enable = true;
        systemd = {
          enable = true;
          # Plasma Login Manager starts UWSM with hyprland.desktop, so that
          # desktop file id is the systemd instance name.
          autoStart = true;
          target = uwsmHyprlandTarget;
        };

        settings = {
          telemetry.system_info = false;
          search_files_in_root = false;

          theme = {
            dark = {
              name = lib.mkForce "catppuccin-mocha";
              iconTheme = lib.mkForce "Catppuccin Mocha Blue";
            };
            light = {
              name = lib.mkForce "catppuccin-latte";
              iconTheme = lib.mkForce "Catppuccin Latte Blue";
            };
          };

          providers.applications.preferences.launchPrefix = "${uwsmApp} --";

          launcher_window.layer_shell = {
            enabled = true;
            # Vicinae's default "exclusive" mode warns about Hyprland popup
            # interaction issues; on-demand still grabs keyboard focus when open.
            keyboard_interactivity = "on_demand";
            layer = "top";
          };
        };
      };

      wayland.windowManager.hyprland.settings.bind = [
        (bind "SUPER+Space" ''hl.dsp.exec_cmd("${vicinaeBin} toggle")'')
      ];
    })
  ];
}
