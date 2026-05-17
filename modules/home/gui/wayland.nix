{
  config,
  lib,
  ...
}:
let
  cfg = config.homeconfig.gui;
in
{
  # Wayland session variables that apply to any compositor (Hyprland, GNOME, KDE…).
  # Gated only on the GUI category enable — no compositor-specific toggle needed.
  config = lib.mkIf cfg.enable {
    home.sessionVariables = {
      NIXOS_OZONE_WL = "1"; # Chromium / Electron apps: use Wayland backend
      GDK_BACKEND = "wayland,x11,*"; # GTK: prefer Wayland, fall back to X11
      QT_QPA_PLATFORM = "wayland;xcb"; # Qt: prefer Wayland, fall back to xcb
    };
  };
}
