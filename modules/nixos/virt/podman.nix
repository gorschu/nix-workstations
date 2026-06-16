{ config, lib, ... }:
let
  cfg = config.nixconfig.podman;
in
{
  options.nixconfig.podman.enable = lib.mkEnableOption "podman container runtime";

  config = lib.mkIf cfg.enable {
    virtualisation.podman = {
      enable = true;
      defaultNetwork.settings.dns_enabled = true;
    };
  };
}
