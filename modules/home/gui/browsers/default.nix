{ lib, ... }:
let
  repoLib = import ../../../../lib { inherit lib; };
in
{
  # Auto-import all browser modules
  # Individual browser modules control themselves via homeconfig.gui.browsers.enable
  imports = repoLib.importNixModules ./.;
}
