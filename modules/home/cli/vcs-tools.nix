{
  config,
  lib,
  ...
}:
let
  cfg = config.homeconfig.cli;
in
{
  config = lib.mkIf (cfg.enable && cfg.development.enable) {
    catppuccin = {
      gh-dash.enable = true;
      lazygit.enable = true;
    };

    home.shellAliases = {
      g = "git";
      lg = "lazygit";
    };

    programs = {
      difftastic = {
        enable = true;
        options = {
          background = "dark";
          color = "auto";
          display = "side-by-side";
        };
        git = {
          enable = true;
          mode = "both";
        };
      };

      gh = {
        enable = true;
        settings = {
          git_protocol = "ssh";
          prompt = "enabled";
        };
      };

      gh-dash.enable = true;
      lazygit.enable = true;
    };
  };
}
