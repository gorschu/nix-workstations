{ config, ... }:
{
  # Set this to the actual disk device path after booting the installer:
  # ls /dev/disk/by-id/ | grep -v part
  disko.devices.disk.main.device = "/dev/disk/by-id/FIXME";

  nixpkgs.hostPlatform = "x86_64-linux";
  networking.hostName = "apollo";

  rootSshKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKHpVzgsHl+TsjfyfAdRKpF55Q658/M3RBj03HzMdAaa root@general"
  ];

  nixconfig = {
    networking = {
      enable = true;
      tailscale = {
        enable = true;
        autoconnect = true;
      };
    };
    storage = {
      zswap.enable = true;
      backup = {
        enable = true;
        targets = {
          b2 = {
            repository = "b2:${config.nixconfig.storage.backup.bucketName}:/backup-${config.networking.hostName}";
            backend = "b2";
          };
        };
      };
    };
  };

  system.stateVersion = "26.05";
}
