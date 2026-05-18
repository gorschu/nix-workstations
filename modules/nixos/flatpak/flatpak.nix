{
  config,
  lib,
  ...
}:
let
  cfg = config.nixconfig.flatpak;
in
{
  options.nixconfig.flatpak = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Flatpak support (nix-flatpak). Exposes services.flatpak.packages for declarative app management.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.flatpak.enable = true;
  };
}
