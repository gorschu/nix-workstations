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
    # To use the `nix` from `inputs.nixpkgs` on templates using the standalone `home-manager` template

    # `nix.package` is already set if on `NixOS`.
    # TODO: Avoid setting `nix.package` in two places when Home Manager runs on NixOS.
    nix.package = lib.mkDefault pkgs.nix;
    home.packages = [
      config.nix.package
    ];
  };
}
