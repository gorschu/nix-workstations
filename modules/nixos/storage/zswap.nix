{ config, lib, ... }:
let
  cfg = config.nixconfig.storage.zswap;
in
{
  options.nixconfig.storage.zswap = {
    enable = lib.mkEnableOption "zswap compressed swap cache";
  };

  config = lib.mkIf cfg.enable {
    boot.zswap.enable = true;
  };
}
