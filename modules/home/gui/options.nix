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

    desktop = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable desktop integration (XDG portals, MIME associations)";
      };
    };
  };
}
