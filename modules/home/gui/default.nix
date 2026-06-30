{ lib, ... }:
let
  repoLib = import ../../../lib { inherit lib; };
in
{
  # Import all GUI modules unconditionally
  # They will be controlled via homeconfig.gui.enable and sub-options
  imports = repoLib.importNixModules ./.;
}
