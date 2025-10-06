{ flake, ... }:
{
  imports = [
    ./gnome.nix
    ./fonts.nix
    flake.inputs.self.nixosModules._1password
  ];

  # Enable GNOME by default when gui module is imported
  nixconfig.gnome.enable = true;

  # Enable 1Password by default for GUI systems
  nixconfig._1password.enable = true;
}
