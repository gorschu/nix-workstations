{ lib, ... }:
let
  repoLib = import ../../../lib { inherit lib; };
in
{
  # Core modules are always imported, but some have enable options (like SSH)
  imports = repoLib.importNixModules ./.;

  # Enable SSH by default
  nixconfig.ssh.enable = lib.mkDefault true;

  # Allow unfree packages globally
  nixpkgs.config.allowUnfree = true;
}
