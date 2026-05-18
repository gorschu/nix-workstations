{
  config,
  lib,
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
      description = "Enable base gaming support: GameMode (with cap_sys_nice renice)";
    };

    steam = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Install Steam via Flatpak (requires nixconfig.flatpak.enable)";
      };
    };

    lutris = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Install Lutris via Flatpak (requires nixconfig.flatpak.enable)";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # GameMode: must use the module (not bare package) for cap_sys_nice renice support
    programs.gamemode.enable = true;

    assertions = [
      {
        assertion = !cfg.steam.enable || config.nixconfig.flatpak.enable;
        message = "nixconfig.gaming.steam.enable requires nixconfig.flatpak.enable = true";
      }
      {
        assertion = !cfg.lutris.enable || config.nixconfig.flatpak.enable;
        message = "nixconfig.gaming.lutris.enable requires nixconfig.flatpak.enable = true";
      }
    ];

    services.flatpak.packages =
      (lib.optional cfg.steam.enable "com.valvesoftware.Steam")
      ++ (lib.optional cfg.lutris.enable "net.lutris.Lutris");
  };
}
