{
  config,
  lib,
  inputs,
  pkgs,
  ...
}:
let
  cfg = config.homeconfig.cli;
in
{
  imports = [
    inputs.nixvim.homeModules.nixvim
  ];

  config = lib.mkIf (cfg.enable && cfg.editor.enable) {
    programs.nixvim = (import ./nixvim.nix { inherit pkgs; }) // {
      enable = true;
    };
  };
}
