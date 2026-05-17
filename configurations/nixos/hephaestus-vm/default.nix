{ lib, ... }:
{
  imports = [
    ../_shared/workstation-profile.nix
    ../hephaestus/configuration.nix
  ];

  # Hardware configuration via nixos-facter
  facter.reportPath = ./facter.json;

  # VM-specific configuration
  nixconfig = {
    virt = {
      qemuGuest.enable = true;
      virtioDiskLinks.enable = true;
    };
    networking.tailscale.enable = lib.mkForce false;
    storage.backup.enable = lib.mkForce false;
  };

  # Use raw device for disko (installer doesn't have udev links yet)
  # The virtio-disk-links module creates stable links for the booted system
  disko.devices.disk.main.device = lib.mkForce "/dev/vda";
}
