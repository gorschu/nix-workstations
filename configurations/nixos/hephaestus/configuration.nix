# Hardware and system-specific configuration for hephaestus
{ config, flake, ... }:
{
  # No extra imports needed - restic-backup is now part of storage module

  # Disk device for disko
  disko.devices.disk.main.device = "/dev/disk/by-id/nvme-SAMSUNG_MZVLW512HMJP-000L7_S359NX0HC16935_1";

  nixpkgs.hostPlatform = "x86_64-linux";
  networking.hostName = "hephaestus";

  # Storage configuration (moved to base.nix)
  # nixconfig.storage.zfs.enable is set in profiles/base.nix

  # SOPS secrets for user passwords
  sops.secrets."root/password" = {
    sopsFile = flake.inputs.self + /secrets/hosts/${config.networking.hostName}/users.yaml;
    neededForUsers = true;
  };
  sops.secrets."gorschu/password" = {
    sopsFile = flake.inputs.self + /secrets/hosts/${config.networking.hostName}/users.yaml;
    neededForUsers = true;
  };

  # Root SSH keys
  rootSshKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKHpVzgsHl+TsjfyfAdRKpF55Q658/M3RBj03HzMdAaa root@general"
  ];

  # User configuration
  users = {
    mutableUsers = false;
    users.root.hashedPasswordFile = config.sops.secrets."root/password".path;
    users.gorschu.hashedPasswordFile = config.sops.secrets."gorschu/password".path;
  };

  # Enable restic backups
  nixconfig.storage.backup = {
    enable = true;
    # bucketName = "gorschu-backup-workstations";  # default, can override for servers
    targets = {
      b2 = {
        repository = "b2:${config.nixconfig.storage.backup.bucketName}:/backup-${config.networking.hostName}";
        backend = "b2";
      };
      # Optional: Add Scaleway as second target (uses S3-compatible API)
      # scaleway = {
      #   repository = "s3:s3.nl-ams.scw.cloud/${config.nixconfig.storage.backup.bucketName}/backup-${config.networking.hostName}";
      #   backend = "s3";
      # };
    };
  };

  # Used for backwards compatibility, please read the changelog before changing.
  # $ nixos-rebuild changelog
  system.stateVersion = "25.11";
}
