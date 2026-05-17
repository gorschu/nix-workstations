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

    environment.systemPackages = with pkgs.kdePackages; [
      filelight
      kdeconnect-kde
      kgpg
      kwalletmanager
    ];
  };
}
