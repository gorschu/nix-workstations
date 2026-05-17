{
  config,
  lib,
  ...
}:
let
  cfg = config.homeconfig.gui;
in
{
  config = lib.mkIf (cfg.enable && cfg.desktop.enable) {
    wayland.windowManager.hyprland = {
      enable = true;
      # Package and portal managed by NixOS programs.hyprland — don't double-install.
      # Requires home-manager >= 5dc1c2e.
      package = null;
      portalPackage = null;
    };

    # With UWSM, Hyprland is launched as a systemd unit and does not source
    # a login shell. Point the UWSM env file at Home Manager's generated
    # session-vars script so that all home.sessionVariables reach the session.
    xdg.configFile."uwsm/env".source =
      "${config.home.sessionVariablesPackage}/etc/profile.d/hm-session-vars.sh";
  };
}
