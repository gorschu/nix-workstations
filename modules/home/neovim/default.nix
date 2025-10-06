{ flake, pkgs, ... }:
{
  imports = [
    flake.inputs.nixvim.homeModules.nixvim
  ];

  programs.nixvim = (import ./nixvim.nix { inherit pkgs; }) // {
    enable = true;
  };
}
