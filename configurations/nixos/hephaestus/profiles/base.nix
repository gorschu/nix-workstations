# Shared base configuration for hephaestus (both physical and VM)
{ inputs, ... }:
{
  imports = [
    # System infrastructure
    inputs.disko.nixosModules.disko
    inputs.nixos-facter-modules.nixosModules.facter
    inputs.sops-nix.nixosModules.sops

    # Shared ZFS workstation disk layout
    ../../_shared/workstation-disko.nix

    ../configuration.nix
  ];

  # Enable GUI and ZFS for this machine
  nixconfig.gui.enable = true;
  nixconfig.hyprland.enable = true;
  nixconfig.storage.zfs.enable = true;
}
