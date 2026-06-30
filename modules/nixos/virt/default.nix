{ lib, ... }:
let
  repoLib = import ../../../lib { inherit lib; };
in
{
  # Virt modules define their own options and enable guards
  imports = repoLib.importNixModules ./.;
}
