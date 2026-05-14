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
        ignores = [
          "*~"
          "*.swp"
        ];
        settings = {
          user.name = config.me.fullname;
          user.email = config.me.email;
          alias.ci = "commit";
          init.defaultBranch = "main";
        };
      };
      lazygit.enable = true;
    };
  };
}
