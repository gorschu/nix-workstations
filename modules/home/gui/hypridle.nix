{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.homeconfig.gui;
  hyprlandStackEnabled = cfg.hyprland.enable;
  hypridleEnabled = cfg.hyprland.hypridle.enable;
  hyprlandEnabled = config.wayland.windowManager.hyprland.enable;
  noctaliaEnabled = config.programs.noctalia.enable or false;

  inherit (lib.generators) mkLuaInline;

  systemdBin = "${pkgs.systemd}/bin";
  systemctl = "${systemdBin}/systemctl";
  loginctl = "${systemdBin}/loginctl";
  acPower = "${systemdBin}/systemd-ac-power";
  brightnessctl = lib.getExe pkgs.brightnessctl;
  ddcutil = lib.getExe pkgs.ddcutil;
  hyprlandPackage = pkgs.hyprland;
  hyprctl = "${hyprlandPackage}/bin/hyprctl";

  noctalia = lib.getExe config.programs.noctalia.package;
  lockCmd = "${noctalia} msg session lock";
  dpms = action: "${hyprctl} dispatch 'hl.dsp.dpms({ action = \"${action}\" })'";
  onBattery = command: "${acPower} || (${command})";
  onAc = command: "${acPower} && (${command})";
  uwsmHyprlandTarget = "wayland-session@hyprland.desktop.target";

  bind = key: command: {
    _args = [
      key
      (mkLuaInline "hl.dsp.exec_cmd(${builtins.toJSON command})")
    ];
  };
in
{
  config = lib.mkMerge [
    (lib.mkIf (cfg.enable && hyprlandStackEnabled && hypridleEnabled) {
      assertions = [
        {
          assertion = hyprlandEnabled;
          message = "homeconfig.gui.hyprland.hypridle.enable requires Hyprland to be enabled.";
        }
        {
          assertion = noctaliaEnabled;
          message = "homeconfig.gui.hyprland.hypridle.enable currently uses Noctalia as its locker.";
        }
      ];
    })

    (lib.mkIf
      (cfg.enable && hyprlandStackEnabled && hypridleEnabled && hyprlandEnabled && noctaliaEnabled)
      {
        services.hypridle = {
          enable = true;
          # Plasma Login Manager starts UWSM with hyprland.desktop, so that
          # desktop file id is the systemd instance name.
          systemdTarget = uwsmHyprlandTarget;
          settings = {
            general = {
              lock_cmd = lockCmd;
              before_sleep_cmd = lockCmd;
              after_sleep_cmd = dpms "enable";
            };

            listener = [
              {
                timeout = 150;
                on-timeout = "${brightnessctl} -sd rgb:kbd_backlight set 0";
                on-resume = "${brightnessctl} -rd rgb:kbd_backlight";
              }
              {
                timeout = 300;
                on-timeout = "${brightnessctl} -s set 10";
                on-resume = "${brightnessctl} -r";
              }
              {
                timeout = 300;
                on-timeout = "${ddcutil} setvcp 10 5";
                on-resume = "${ddcutil} setvcp 10 100";
              }
              {
                timeout = 300;
                on-timeout = "${loginctl} lock-session";
              }
              {
                timeout = 600;
                on-timeout = onBattery (dpms "disable");
                on-resume = onBattery "${dpms "enable"} && ${brightnessctl} -r";
              }
              {
                timeout = 900;
                on-timeout = onAc (dpms "disable");
                on-resume = onAc "${dpms "enable"} && ${brightnessctl} -r";
              }
              {
                timeout = 1800;
                on-timeout = onBattery "${systemctl} suspend";
              }
              {
                timeout = 3600;
                on-timeout = "${systemctl} suspend";
              }
            ];
          };
        };

        wayland.windowManager.hyprland.settings.bind = [
          (bind "SUPER+ALT+L" "${loginctl} lock-session")
        ];
      }
    )
  ];
}
