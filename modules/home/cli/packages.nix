{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.homeconfig.cli;
in
{
  config = lib.mkIf (cfg.enable && cfg.system.enable) {
    # Nix packages to install to $HOME
    #
    # Search for packages here: https://search.nixos.org/packages
    home.packages = with pkgs; [
      omnix

      # Unix tools
      sd
      tree
      gnumake

      # Nix dev
      cachix
      nil # Nix language server
      nix-info
      nixfmt
    ];

    # Programs natively supported by home-manager.
    # They can be configured in `programs.*` instead of using home.packages.
    programs = {
      less.enable = true;
      ripgrep.enable = true;
      jq.enable = true;
      btop.enable = true;
      # Tmate terminal sharing.
      tmate = {
        enable = true;
        #host = ""; #In case you wish to use a server other than tmate.io
      };
    };
  };
}
