{
  config,
  lib,
  inputs,
  pkgs,
  ...
}:
let
  cfg = config.homeconfig.gui;
  hyprlandEnabled = config.wayland.windowManager.hyprland.enable;
  noctaliaBin = lib.getExe config.programs.noctalia.package;
  uwsm = lib.getExe pkgs.uwsm;
  noctaliaLaunch = "${uwsm} app -- ${noctaliaBin}";

  inherit (lib.generators) mkLuaInline;
  # `hl.dsp.exec_cmd("<cmd>")` as a raw Lua dispatcher expression.
  dispatch = cmd: mkLuaInline "hl.dsp.exec_cmd(${builtins.toJSON cmd})";
  # One Noctalia IPC keybind: hl.bind("<key>", hl.dsp.exec_cmd("noctalia msg <msg>")).
  ncBind = key: msg: {
    _args = [
      key
      (dispatch "noctalia msg ${msg}")
    ];
  };
in
{
  imports = [ inputs.noctalia.homeModules.default ];

  config = lib.mkMerge [
    (lib.mkIf (cfg.enable && cfg.noctalia.enable) {
      assertions = [
        {
          assertion = hyprlandEnabled;
          message = "homeconfig.gui.noctalia.enable requires Hyprland to be enabled.";
        }
      ];
    })

    (lib.mkIf (cfg.enable && cfg.noctalia.enable && hyprlandEnabled) {
      programs.noctalia = {
        enable = true;
        # Launched through UWSM from Hyprland (start hook below), not as a
        # Noctalia-managed user service.
        systemd.enable = false;

        # Declarative (read-only) config. Start minimal; extend iteratively.
        settings = {
          bar = {
            # "default" is the active bar (bar.order = [ "default" ]); a bar
            # named "main" would need adding to that order to be shown.
            default = {
              font_family = "Adwaita Sans";
              font_weight = "regular";
              margin_ends = 40;
              scale = 1.0;
              start = [
                "launcher"
                "workspaces"
              ];
            };
          };
          theme = {
            mode = "dark";
            source = "builtin";
            builtin = "Catppuccin";
          };
          # Per-widget settings live under `widget.<name>` (singular). `widgets`
          # is not a recognized section and is silently ignored.
          widget = {
            workspaces = {
              minimal = false;
              labels_only_when_occupied = false;
              hide_when_empty = false;
              pill_scale = 1.0; # max is 1.0
            };
          };
        };
      };

      # Noctalia-owned Hyprland integration, per the Noctalia v5 Hyprland docs.
      # configType = "lua" (set in hyprland.nix) renders these to hyprland.lua as
      # hl.<key>(...) calls.
      wayland.windowManager.hyprland.settings = {
        # Start Noctalia inside Hyprland only.
        on = [
          {
            _args = [
              "hyprland.start"
              (mkLuaInline "function() hl.exec_cmd(${builtins.toJSON noctaliaLaunch}) end")
            ];
          }
        ];

        bind = [
          (ncBind "SUPER+S" "panel-toggle control-center")
          (ncBind "SUPER+comma" "settings-toggle")
          (ncBind "XF86AudioRaiseVolume" "volume-up")
          (ncBind "XF86AudioLowerVolume" "volume-down")
          (ncBind "XF86AudioMute" "volume-mute")
          (ncBind "XF86MonBrightnessUp" "brightness-up")
          (ncBind "XF86MonBrightnessDown" "brightness-down")
        ];

        layer_rule = {
          name = "noctalia";
          match.namespace = "^noctalia-(bar-.+|notification|dock|panel|attached-panel|osd)$";
          ignore_alpha = 0.5;
          blur = true;
          blur_popups = true;
        };
      };
    })
  ];
}
