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
  config = lib.mkIf (cfg.enable && cfg.shell.enable) {
    home.shellAliases = {
      ssh-yolo = "ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null";
    };

    programs = {
      bash = {
        enable = true;
        # bashrcExtra runs at the very top of .bashrc, before any other initialization
        # This is ideal for exec'ing zsh early, avoiding unnecessary bash setup
        bashrcExtra = ''
          # Auto-launch zsh from bash for interactive sessions
          # Keeps bash as login shell to avoid breaking system services/display managers
          # Source: https://tim.siosm.fr/blog/2023/12/22/dont-change-defaut-login-shell/
          # Only trigger if:
          # - we are in an interactive session (not checking this e.g. breaks SDDM/KDE login)
          # - 'zsh' is not the parent process of this shell
          # - We did not call: bash -c '...'
          if [[ $- == *i* && $(ps --no-header --pid=$PPID --format=comm) != "zsh" && -z ''${BASH_EXECUTION_STRING} ]]; then
            shopt -q login_shell && LOGIN_OPTION='--login' || LOGIN_OPTION=""
            exec ${pkgs.zsh}/bin/zsh $LOGIN_OPTION
          fi
        '';
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
