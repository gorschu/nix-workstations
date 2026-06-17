{ lib, ... }:
{
  # Two-level enable pattern:
  # 1. Category level (homeconfig.gui.enable) - master switch for all GUI
  # 2. Subcategory level (homeconfig.gui.browsers.enable) - fine-grained control
  # Individual modules check: cfg.enable && cfg.subcategory.enable

  options.homeconfig.gui = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable all GUI modules";
    };

    browsers = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable web browsers (firefox, etc.)";
      };
    };

    fonts = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable font configuration and substitutions";
      };
    };

    catppuccin = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable Catppuccin theme defaults";
      };
    };

    terminals = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable terminal emulator configuration (kitty)";
      };
    };

    vicinae = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable Vicinae launcher integration";
      };
    };

    desktop = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable desktop integration (XDG portals, MIME associations)";
      };
    };

    noctalia = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable Noctalia desktop shell integration";
      };
    };

    hypridle = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable Hyprland idle handling via hypridle";
      };
    };

    plasma = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable KDE Plasma declarative configuration via plasma-manager";
      };
    };
  };
}
