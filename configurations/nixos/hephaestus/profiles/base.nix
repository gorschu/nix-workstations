# Shared base configuration for hephaestus (both physical and VM)
{ inputs, ... }:
{
  imports = [
    # System infrastructure
    inputs.disko.nixosModules.disko
    inputs.nixos-facter-modules.nixosModules.facter
    inputs.sops-nix.nixosModules.sops

    # Disk and hardware configuration
    ../disko.nix
    ../configuration.nix
  ];

  # Enable GUI and ZFS for this machine
  nixconfig.gui.enable = true;
  nixconfig.hyprland.enable = true;
  nixconfig.storage.zfs.enable = true;
}
