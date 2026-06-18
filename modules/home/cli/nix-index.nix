{
  config,
  lib,
  inputs,
  ...
}:
let
  cfg = config.homeconfig.cli;
in
{
  imports = [
    # NOTE: The nix-index DB is slow to search, until
    # https://github.com/nix-community/nix-index-database/issues/130
    inputs.nix-index-database.homeModules.nix-index
  ];

  config = lib.mkIf (cfg.enable && cfg.development.enable) {
    # command-not-found handler to suggest nix way of installing stuff.
    # FIXME: This ought to show new nix cli commands though:
    # https://github.com/nix-community/nix-index/issues/191
    programs.nix-index = {
      enable = true;
      enableZshIntegration = false;
    };
    programs.nix-index-database.comma.enable = true;
  };
}
