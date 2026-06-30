{ lib, ... }:
let
  repoLib = import ../../../lib { inherit lib; };
in
{
  # Always import all CLI modules unconditionally
  # Individual modules control themselves via homeconfig.cli.* options
  imports = repoLib.importNixModules ./.;
}
