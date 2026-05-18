{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.nixconfig.gaming;
in
{
  options.nixconfig.gaming = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable base gaming support: GameMode (with cap_sys_nice) and 32-bit graphics";
    };

    steam = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable Steam (includes 32-bit graphics, udev rules, PipeWire 32-bit)";
      };
    };

    lutris = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable Lutris game manager";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # GameMode: must use the module (not bare package) for cap_sys_nice renice support
    programs.gamemode.enable = true;

    # 32-bit graphics needed for Wine/Proton-based games.
    # programs.steam.enable sets this automatically, but Lutris does not.
    hardware.graphics.enable32Bit = true;

    programs.steam = lib.mkIf cfg.steam.enable {
      enable = true;
      # hardware.graphics.enable32Bit, hardware.steam-hardware, and
      # PipeWire 32-bit support are all set automatically by the steam module.
    };

    environment.systemPackages = lib.mkIf cfg.lutris.enable (with pkgs; [ lutris ]);
  };
}
