{ flake, ... }:
{
  imports = [
    ./locale.nix
    ./networking.nix
    ./users.nix
    flake.inputs.self.nixosModules.ssh
  ];

  # SSH is configured via the ssh module
  nixconfig.ssh.enable = true;

  # Allow unfree packages globally
  nixpkgs.config.allowUnfree = true;
}
