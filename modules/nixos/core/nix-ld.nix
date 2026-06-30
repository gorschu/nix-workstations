{ config, lib, ... }:
let
  cfg = config.nixconfig.nix-ld;
in
{
  options.nixconfig.nix-ld.enable = lib.mkEnableOption "nix-ld for unpatched dynamic binaries";

  config = lib.mkIf cfg.enable {
    programs.nix-ld.enable = true;
  };
}
