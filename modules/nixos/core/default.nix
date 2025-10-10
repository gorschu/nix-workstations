{ lib, ... }:
let
  inherit (builtins) readDir attrNames filter;
in
{
  # Core modules are always imported, but some have enable options (like SSH)
  imports = map (fn: ./${fn}) (filter (fn: fn != "default.nix") (attrNames (readDir ./.)));

  # Enable SSH by default
  nixconfig.ssh.enable = lib.mkDefault true;

  # Allow unfree packages globally
  nixpkgs.config.allowUnfree = true;
}
