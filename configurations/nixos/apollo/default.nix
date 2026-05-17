{ inputs, ... }:
{
  imports = [
    inputs.disko.nixosModules.disko
    inputs.nixos-facter-modules.nixosModules.facter
    inputs.sops-nix.nixosModules.sops

    ../_shared/workstation-disko.nix

    ./configuration.nix
  ];

  facter.reportPath = ./facter.json;

  nixconfig.gui.enable = true;
  nixconfig.hyprland.enable = true;
  nixconfig.storage.zfs.enable = true;
}
