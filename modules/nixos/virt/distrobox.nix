{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.nixconfig.distrobox;
in
{
  options.nixconfig.distrobox.enable = lib.mkEnableOption "distrobox (requires podman)";

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.nixconfig.podman.enable;
        message = "nixconfig.distrobox.enable requires nixconfig.podman.enable = true";
      }
    ];

    environment.systemPackages = with pkgs; [
      distrobox
    ];
  };
}
