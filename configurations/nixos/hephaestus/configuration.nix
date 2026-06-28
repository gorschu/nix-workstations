# Hardware and system-specific configuration for hephaestus
{ config, ... }:
{
  disko.devices.disk.main.device = "/dev/disk/by-id/nvme-SAMSUNG_MZVLW512HMJP-000L7_S359NX0HC16935_1";

  nixpkgs.hostPlatform = "x86_64-linux";
  networking.hostName = "hephaestus";

  # Hyprland/Aquamarine on this Kaby Lake iGPU fails atomic commits for the
  # Philips 5120x1440 mode when using Intel Y_TILED_CCS buffer modifiers.
  environment.sessionVariables.AQ_NO_MODIFIERS = "1";

  rootSshKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKHpVzgsHl+TsjfyfAdRKpF55Q658/M3RBj03HzMdAaa root@general"
  ];

  nixconfig = {
    plasma.enable = true;
    hyprland.enable = false;
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
            repository = "b2:${config.nixconfig.storage.backup.bucketName}:${config.networking.hostName}";
            backend = "b2";
          };
        };
      };
    };
  };

  system.stateVersion = "26.05";
}
