{ ... }:
{
  imports = [
    ../_shared/workstation-profile.nix
    ./configuration.nix
  ];

  facter.reportPath = ./facter.json;
}
