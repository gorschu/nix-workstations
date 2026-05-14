{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.homeconfig.cli;
in
{
  config = lib.mkIf (cfg.enable && cfg.system.enable) {
    nix.package = lib.mkDefault pkgs.nix;
    # Only add nix to user packages on standalone HM; on NixOS, nix.enable is
    # false (NixOS manages the nix daemon) and nix is already system-wide.
    home.packages = lib.mkIf config.nix.enable [ config.nix.package ];
  };
}
