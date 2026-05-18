{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.nixconfig.kde;
in
{
  options.nixconfig.kde = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable KDE Plasma 6 desktop environment with Plasma Login Manager";
    };
  };

  config = lib.mkIf cfg.enable {
    services.desktopManager.plasma6.enable = true;
    services.displayManager.plasma-login-manager.enable = true;

    # Drop the X11 session — Wayland only. XWayland is still available for
    # individual apps that need it (enabled automatically by plasma6).
    environment.plasma6.excludePackages = with pkgs.kdePackages; [ kwin-x11 ];

    environment.systemPackages = with pkgs.kdePackages; [
      kdeconnect-kde
      kwalletmanager
    ];
  };
}
