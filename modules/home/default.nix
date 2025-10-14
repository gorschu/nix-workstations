# Core home-manager configuration
# Import user metadata and module groups
# Control what's enabled via homeconfig.cli.enable and homeconfig.gui.enable
{
  imports = [
    ./me.nix # User metadata (always loaded)
    ./sops.nix # SOPS configuration (always loaded)
    ./cli
    ./gui
  ];
}
