{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.nixconfig.gnome;
in
{
  options.nixconfig.gnome = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable GNOME desktop environment with GDM";
    };
  };

  config = lib.mkIf cfg.enable {
    services = {
      xserver.enable = true;
      displayManager.gdm.enable = true;
      desktopManager.gnome.enable = true;
    };

    environment.systemPackages = with pkgs; [
      gnome-tweaks
      papers # PDF viewer
    ];

    # Remove GNOME Console; terminal emulator is managed via Home Manager.
    environment.gnome.excludePackages = with pkgs; [
      gnome-console
    ];
  };
}
