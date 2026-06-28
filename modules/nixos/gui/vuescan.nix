{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.nixconfig.gui.vuescan;
in
{
  options.nixconfig.gui.vuescan = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable VueScan and install its scanner udev rules.";
    };
  };

  config = lib.mkIf (config.nixconfig.gui.enable && cfg.enable) {
    environment.systemPackages = [ pkgs.vuescan ];
    services.udev.packages = [ pkgs.vuescan ];
  };
}
