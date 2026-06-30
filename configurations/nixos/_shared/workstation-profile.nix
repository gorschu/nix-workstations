{ inputs, ... }:
{
  imports = [
    inputs.disko.nixosModules.disko
    inputs.nixos-facter-modules.nixosModules.facter
    inputs.sops-nix.nixosModules.sops

    ./workstation-disko.nix
  ];

  nixconfig.gui.enable = true;
  nixconfig.nix-ld.enable = true;
  nixconfig.storage.zfs.enable = true;

  nixconfig.podman = {
    enable = true;
    storage = {
      enable = true;
      rootlessUsers = [ "gorschu" ];
    };
  };
  nixconfig.distrobox.enable = true;
}
