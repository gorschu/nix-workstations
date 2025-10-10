{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.nixconfig.storage.zfs;
in
{
  options.nixconfig.storage.zfs = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable and configure ZFS options";
    };
  };

  config = lib.mkIf cfg.enable {
    boot = {
      kernelPackages = lib.mkDefault pkgs.linuxPackages;
      supportedFilesystems = [ "zfs" ];
      zfs.forceImportRoot = false;
      initrd.supportedFilesystems = [ "zfs" ];
    };

    networking.hostId = builtins.substring 0 8 (
      builtins.hashString "sha256" config.networking.hostName
    );

    services.zfs = {
      autoScrub.enable = true;
      trim.enable = true;
    };
  };
}
