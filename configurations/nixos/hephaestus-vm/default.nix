{ lib, flake, ... }:
{
  imports = [
    ../hephaestus/profiles/base.nix
    flake.inputs.self.nixosModules.qemu-guest
    flake.inputs.self.nixosModules.virtio-disk-links
  ];

  # Enable virtio disk link creation for VM environments
  nixconfig.virtio-disk-links.enable = true;

  # Use raw device for disko (installer doesn't have udev links yet)
  # The virtio-disk-links module creates stable links for the booted system
  disko.devices.disk.main.device = lib.mkForce "/dev/vda";
}
