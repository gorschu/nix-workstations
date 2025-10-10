# Git configuration module
# Template for home-manager CLI modules following the two-level enable pattern
{ config, lib, ... }:
let
  # Reference the category-level config (cli or gui)
  cfg = config.homeconfig.cli;
in
{
  # Configuration wrapped in mkIf checking both category and subcategory
  # This is the required pattern: cfg.enable && cfg.subcategory.enable
  config = lib.mkIf (cfg.enable && cfg.development.enable) {
    home.shellAliases = {
      g = "git";
      lg = "lazygit";
    };

    # https://nixos.asia/en/git
    programs = {
      git = {
        enable = true;
        # Use config.me.* for user metadata defined in modules/home/me.nix
        userName = config.me.fullname;
        userEmail = config.me.email;
        ignores = [
          "*~"
          "*.swp"
        ];
        aliases = {
          ci = "commit";
        };
        extraConfig = {
          # init.defaultBranch = "master";
          # pull.rebase = "false";
        };
      };
      lazygit.enable = true;
    };
  };
}
