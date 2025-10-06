# Shared base configuration for hephaestus (both physical and VM)
{ flake, ... }:

let
  inherit (flake) inputs;
  inherit (inputs) self;
in
{
  imports = [
    self.nixosModules.default
    self.nixosModules.gui
    self.nixosModules.zfs

    # System infrastructure
    inputs.disko.nixosModules.disko
    inputs.nixos-facter-modules.nixosModules.facter
    inputs.sops-nix.nixosModules.sops

    # Disk and hardware configuration
    ../disko.nix
    ../configuration.nix
  ];
}
