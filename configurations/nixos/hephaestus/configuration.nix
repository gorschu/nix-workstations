# Hardware and system-specific configuration for hephaestus
{ config, ... }:
{
  disko.devices.disk.main.device = "/dev/disk/by-id/nvme-SAMSUNG_MZVLW512HMJP-000L7_S359NX0HC16935_1";

  nixpkgs.hostPlatform = "x86_64-linux";
  networking.hostName = "hephaestus";

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
