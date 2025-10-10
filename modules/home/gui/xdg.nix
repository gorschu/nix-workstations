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
  config = lib.mkIf (cfg.enable && cfg.desktop.enable) {
    # XDG GUI-specific configuration (portals, MIME associations)
    xdg = {
      # MIME type associations for default applications
      mimeApps = {
        enable = true;
        # Application-specific defaults are set in their respective modules
        # (e.g., firefox.nix sets browser defaults)
        defaultApplications = {
          # Add global defaults here if needed
        };
      };

      # XDG desktop portal configuration
      portal = {
        enable = true;
        xdgOpenUsePortal = true;

        # Provide GTK portal as fallback
        # Compositor-specific modules (hyprland.nix, etc.) can extend this
        extraPortals = with pkgs; [
          xdg-desktop-portal-gtk
        ];

        config.common.default = [ "gtk" ];
      };
    };
  };
}
