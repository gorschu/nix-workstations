{ lib, ... }:
let
  repoLib = import ../../../lib { inherit lib; };
in
{
  # Auto-import all .nix files in this directory except default.nix
  imports = repoLib.importNixModules ./.;
}
