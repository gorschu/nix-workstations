{ lib, ... }:
let
  repoLib = import ../../../lib { inherit lib; };
in
{
  imports = repoLib.importNixModules ./.;
}
