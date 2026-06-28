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
  defaultWorkspace = "1";
  kittyBin = lib.getExe config.programs.kitty.package;
  onePasswordBin = "/run/current-system/sw/bin/1password";
  uwsm = lib.getExe pkgs.uwsm;
  kwalletPamInit = "${pkgs.kdePackages.kwallet-pam}/libexec/pam_kwallet_init";
  resizeModeNotification = "hyprctl notify 6 5000 'rgb(f5c2e7)' fontsize:20 'resize mode: h/j/k/l, Esc exits'";

  inherit (lib.generators) mkLuaInline;
  bindWithOptions = key: dispatcher: options: {
    _args = [
      key
      (mkLuaInline dispatcher)
    ]
    ++ lib.optional (options != null) options;
  };
  bind = key: dispatcher: bindWithOptions key dispatcher null;
  workspaceBind =
    key: workspace:
    bind "SUPER+${key}" "hl.dsp.focus({ workspace = ${builtins.toJSON (toString workspace)} })";
  moveToWorkspaceBind =
    key: workspace:
    bind "SUPER+SHIFT+${key}" "hl.dsp.window.move({ workspace = ${builtins.toJSON (toString workspace)} })";
  directionalBinds =
    modifier: dispatcher:
    map
      (
        direction:
        bind "${modifier}+${direction.key}" "${dispatcher}({ direction = ${builtins.toJSON direction.hypr} })"
      )
      [
        {
          key = "h";
          hypr = "l";
        }
        {
          key = "j";
          hypr = "d";
        }
        {
          key = "k";
          hypr = "u";
        }
        {
          key = "l";
          hypr = "r";
        }
      ];
  resizeBind =
    key: x: y:
    bindWithOptions key
      "hl.dsp.window.resize({ x = ${toString x}, y = ${toString y}, relative = true })"
      {
        repeating = true;
      };
  homeofficeMonitor = mkLuaInline ''
    (function()
      local homeoffice = {}

      local function isHomeofficeMonitor(mon)
        return mon ~= nil
          and (mon.description or ""):find(${builtins.toJSON homeofficeModel}, 1, true) ~= nil
      end

      local function setLaptopEnabled(enabled)
        if homeoffice.laptopEnabled == enabled then
          return
        end

        homeoffice.laptopEnabled = enabled

        if enabled then
          hl.monitor({
            output = ${builtins.toJSON laptopOutput},
            mode = "preferred",
            position = "auto",
            scale = 1.2,
            disabled = false,
          })
        else
          hl.monitor({
            output = ${builtins.toJSON laptopOutput},
            disabled = true,
          })
        end

        -- Keep compatibility with the released nixpkgs Hyprland Lua API. Drop
        -- this guard once all hosts run a Hyprland build exposing this helper.
        if type(hl.exec_scheduled_prop_refresh_immediately) == "function" then
          hl.exec_scheduled_prop_refresh_immediately()
        end

        hl.dsp.focus({ workspace = ${builtins.toJSON defaultWorkspace} })
      end

      function homeoffice.sync()
        for _, mon in ipairs(hl.get_monitors()) do
          if isHomeofficeMonitor(mon) then
            setLaptopEnabled(false)
            return
          end
        end

        setLaptopEnabled(true)
      end

      function homeoffice.added(mon)
        if isHomeofficeMonitor(mon) then
          setLaptopEnabled(false)
        end
      end

      function homeoffice.removed(mon)
        if isHomeofficeMonitor(mon) then
          setLaptopEnabled(true)
        end
      end

      return homeoffice
    end)()
  '';
in
{
  config = lib.mkIf (cfg.enable && cfg.hyprland.enable) {
    catppuccin.hyprland.enable = true;

    home.packages = [
      # Provides the GTK3 Adwaita theme used by the Hyprland-only UWSM env.
      pkgs.gnome-themes-extra
    ];

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
        homeofficeMonitor._var = homeofficeMonitor;

        bind = [
          (bind "SUPER+Return" ''hl.dsp.exec_cmd("${uwsm} app -- ${kittyBin} --single-instance")'')
          (bind "SUPER+Q" "hl.dsp.window.close()")
          (bind "SUPER+Tab" ''hl.dsp.focus({ workspace = "e-1" })'')
          (bind "SUPER+SHIFT+Tab" ''hl.dsp.focus({ workspace = "e+1" })'')
          (bind "SUPER+SHIFT+Space" ''hl.dsp.exec_cmd("${uwsm} app -- ${onePasswordBin} --quick-access")'')
          (bind "SUPER+SHIFT+P" ''hl.dsp.exec_cmd("${uwsm} app -- ${onePasswordBin} --toggle")'')
          (bind "SUPER+grave" ''hl.dsp.workspace.toggle_special("scratch")'')
          (bind "SUPER+SHIFT+grave" ''hl.dsp.window.move({ workspace = "special:scratch" })'')
          (bind "SUPER+R" ''hl.dsp.submap("resize")'')
          (bind "SUPER+G" "hl.dsp.group.toggle()")
          (bind "SUPER+ALT+h" "hl.dsp.group.prev()")
          (bind "SUPER+ALT+l" "hl.dsp.group.next()")
          (bind "SUPER+SHIFT+G" "hl.dsp.window.move({ out_of_group = true })")
          (bindWithOptions "SUPER+mouse:272" "hl.dsp.window.drag()" { mouse = true; })
          (bindWithOptions "SUPER+mouse:273" "hl.dsp.window.resize()" { mouse = true; })
        ]
        ++ directionalBinds "SUPER" "hl.dsp.focus"
        ++ directionalBinds "SUPER+SHIFT" "hl.dsp.window.move"
        ++ map (workspace: workspaceBind (toString workspace) workspace) (lib.range 1 9)
        ++ map (workspace: moveToWorkspaceBind (toString workspace) workspace) (lib.range 1 9);

        monitor = [
          {
            output = "desc:${homeofficeDescription}";
            mode = "5120x1440@75.00Hz";
            position = "0x0";
            scale = mkLuaInline "1.0";
          }
          {
            output = laptopOutput;
            mode = "preferred";
            position = "auto";
            scale = mkLuaInline "1.2";
          }
        ];

        on = lib.mkBefore [
          {
            _args = [
              "hyprland.start"
              (mkLuaInline "homeofficeMonitor.sync")
            ];
          }
          {
            _args = [
              "hyprland.start"
              (mkLuaInline "function() hl.exec_cmd(${builtins.toJSON kwalletPamInit}) end")
            ];
          }
          {
            _args = [
              "monitor.added"
              (mkLuaInline "homeofficeMonitor.added")
            ];
          }
          {
            _args = [
              "monitor.removed"
              (mkLuaInline "homeofficeMonitor.removed")
            ];
          }
          {
            _args = [
              "monitor.layout_changed"
              (mkLuaInline "homeofficeMonitor.sync")
            ];
          }
          {
            _args = [
              "keybinds.submap"
              (mkLuaInline ''
                function(submap)
                  if submap == "resize" then
                    hl.exec_cmd(${builtins.toJSON resizeModeNotification})
                  end
                end
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
            repeat_delay = 250;
            repeat_rate = 40;
          };

          general = {
            gaps_in = 5;
            gaps_out = 10;
          };

          misc.font_family = "Adwaita Sans";

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

        window_rule = {
          name = "1password";
          match.class = "^(1password)$";
          float = true;
          center = true;
          size = [
            1200
            800
          ];
        };

        # Keep regular workspaces alive so shell workspace indicators do not
        # disappear when a workspace is empty. Monitor transitions focus
        # defaultWorkspace explicitly so it is not pinned to one output.
        workspace_rule = map (workspace: {
          workspace = toString workspace;
          persistent = true;
        }) (lib.range 1 9);
      };

      submaps.resize.settings.bind = [
        (resizeBind "h" (-30) 0)
        (resizeBind "j" 0 30)
        (resizeBind "k" 0 (-30))
        (resizeBind "l" 30 0)
        (bind "escape" ''hl.dsp.submap("reset")'')
        (bind "Return" ''hl.dsp.submap("reset")'')
      ];
    };

    # With UWSM, Hyprland is launched as a systemd unit and does not source
    # a login shell. Point the UWSM env file at Home Manager's generated
    # session-vars script so that all home.sessionVariables reach the session.
    xdg.configFile."uwsm/env".source =
      "${config.home.sessionVariablesPackage}/etc/profile.d/hm-session-vars.sh";
    xdg.configFile."uwsm/env-hyprland.desktop".text = ''
      export GTK_THEME=Adwaita:dark
    '';
  };
}
