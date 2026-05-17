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

      # XDG desktop portal configuration.
      # mkDefault so compositor NixOS modules (e.g. programs.hyprland) can defer
      # portal management to the system level by setting enable = false here.
      portal = {
        enable = lib.mkDefault true;
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
