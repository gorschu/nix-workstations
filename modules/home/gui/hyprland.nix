{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.homeconfig.gui;
  laptopOutput = "eDP-1";
  homeofficeDescription = "Philips Consumer Electronics Company 49B2U6903 AU02421006910";
  homeofficeModel = "49B2U6903";
  kittyBin = lib.getExe config.programs.kitty.package;
  uwsm = lib.getExe pkgs.uwsm;
  kwalletPamInit = "${pkgs.kdePackages.kwallet-pam}/libexec/pam_kwallet_init";

  inherit (lib.generators) mkLuaInline;
  bind = key: dispatcher: {
    _args = [
      key
      (mkLuaInline dispatcher)
    ];
  };
  workspaceBind =
    key: workspace:
    bind "SUPER+${key}" "hl.dsp.focus({ workspace = ${builtins.toJSON (toString workspace)} })";
  homeofficeMonitorHook =
    action:
    mkLuaInline ''
      function(mon)
        if mon.description:find(${builtins.toJSON homeofficeModel}, 1, true) ~= nil then
          ${action}
        end
      end
    '';
in
{
  config = lib.mkIf (cfg.enable && cfg.desktop.enable) {
    catppuccin.hyprland.enable = true;

    wayland.windowManager.hyprland = {
      enable = true;
      # Package and portal managed by NixOS programs.hyprland — don't double-install.
      # Requires home-manager >= 5dc1c2e.
      package = null;
      portalPackage = null;
      # UWSM manages graphical-session.target and env import — disable HM's redundant systemd integration.
      systemd.enable = false;
      # Hyprland 0.55 uses Lua config; HM renders `settings` to hyprland.lua.
      configType = "lua";

      settings = {
        bind = [
          (bind "SUPER+Return" ''hl.dsp.exec_cmd("${uwsm} app -- ${kittyBin} --single-instance")'')
          (bind "SUPER+Q" "hl.dsp.window.close()")
        ]
        ++ map (workspace: workspaceBind (toString workspace) workspace) (lib.range 1 9);

        monitor = [
          {
            output = "desc:${homeofficeDescription}";
            mode = "5120x1440@120Hz";
            position = "0x0";
            scale = mkLuaInline "1.0";
            vrr = 1;
          }
          {
            output = laptopOutput;
            mode = "preferred";
            position = "auto";
            scale = mkLuaInline "1.2";
          }
        ];

        on = [
          {
            _args = [
              "hyprland.start"
              (mkLuaInline "function() hl.exec_cmd(${builtins.toJSON kwalletPamInit}) end")
            ];
          }
          {
            _args = [
              "hyprland.start"
              (mkLuaInline ''
                function()
                  local laptop = ${builtins.toJSON laptopOutput}
                  for _, mon in ipairs(hl.get_monitors()) do
                    if mon.description:find(${builtins.toJSON homeofficeModel}, 1, true) ~= nil then
                      hl.exec_cmd("hyprctl keyword monitor " .. laptop .. ",disable")
                      return
                    end
                  end
                end
              '')
            ];
          }
          {
            _args = [
              "monitor.added"
              (homeofficeMonitorHook ''
                hl.exec_cmd("hyprctl keyword monitor ${laptopOutput},disable")
              '')
            ];
          }
          {
            _args = [
              "monitor.removed"
              (homeofficeMonitorHook ''
                hl.exec_cmd("hyprctl keyword monitor ${laptopOutput},preferred,auto,1.2")
              '')
            ];
          }
        ];

        # Renders to hl.config({ ... }). These are generic compositor appearance
        # settings, not Noctalia shell settings.
        config = {
          input = {
            kb_layout = "de";
            kb_variant = "nodeadkeys";
          };

          general = {
            gaps_in = 5;
            gaps_out = 10;
          };

          decoration = {
            rounding = 20;
            rounding_power = 2;

            shadow = {
              enabled = true;
              range = 4;
              render_power = 3;
              color = lib.generators.mkLuaInline "0xee1a1a1a";
            };

            blur = {
              enabled = true;
              size = 3;
              passes = 2;
              vibrancy = 0.1696;
            };
          };
        };

        # Keep regular workspaces alive so shell workspace indicators do not
        # disappear when a workspace is empty. Monitor pinning belongs in
        # host-specific Hyprland config if needed.
        workspace_rule = map (workspace: {
          workspace = toString workspace;
          persistent = true;
        }) (lib.range 1 9);
      };
    };

    # With UWSM, Hyprland is launched as a systemd unit and does not source
    # a login shell. Point the UWSM env file at Home Manager's generated
    # session-vars script so that all home.sessionVariables reach the session.
    xdg.configFile."uwsm/env".source =
      "${config.home.sessionVariablesPackage}/etc/profile.d/hm-session-vars.sh";
  };
}
