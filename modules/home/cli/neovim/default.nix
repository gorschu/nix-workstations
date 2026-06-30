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
    home.sessionVariables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
    };

    programs.nixvim = (import ./nixvim.nix { inherit pkgs; }) // {
      enable = true;
      # Explicitly use our nixpkgs (matches the `follows` in flake.nix) so nixvim
      # stops warning that its pinned nixpkgs has been overridden.
      nixpkgs.source = pkgs.path;
    };
  };
}
