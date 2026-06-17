{
  config,
  lib,
  ...
}:
let
  cfg = config.homeconfig.cli;
in
{
  config = lib.mkIf (cfg.enable && cfg.shell.enable) {
    home.shellAliases = {
      ssh-yolo = "ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null";
    };

    programs = {
      bash = {
        enable = true;
      };

      zsh = {
        enable = true;
        autocd = true;
        autosuggestion.enable = true;
        syntaxHighlighting.enable = true;
        enableCompletion = true;
        envExtra = ''
          # Custom ~/.zshenv goes here
        '';
        profileExtra = ''
          # Custom ~/.zprofile goes here
        '';
        loginExtra = ''
          # Custom ~/.zlogin goes here
        '';
        logoutExtra = ''
          # Custom ~/.zlogout goes here
        '';
      };

      # Type `z <pat>` to cd to some directory
      zoxide.enable = true;

      # Better shell prompt!
      starship = {
        enable = true;
        settings = {
          username = {
            style_user = "blue bold";
            style_root = "red bold";
            format = "[$user]($style) ";
            disabled = false;
            show_always = true;
          };
          hostname = {
            ssh_only = false;
            ssh_symbol = "🌐 ";
            format = "on [$hostname](bold red) ";
            trim_at = ".local";
            disabled = false;
          };
        };
      };
    };
  };
}
