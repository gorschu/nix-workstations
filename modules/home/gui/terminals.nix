{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.homeconfig.gui;
in
{
  config = lib.mkIf (cfg.enable && cfg.terminals.enable) {
    # Ghostty terminal emulator
    programs.ghostty = {
      enable = true;
      enableBashIntegration = true;
      enableZshIntegration = true;
      installBatSyntax = true;
      installVimSyntax = true;

      settings = {
        # Enable all shell integration features
        shell-integration-features = [
          "cursor" # Blinking bar cursor at prompt
          "sudo" # Preserve terminfo with sudo
          "title" # Set window title via shell integration
          "ssh-env" # SSH environment variable compatibility
          "ssh-terminfo" # Automatic terminfo installation on remote hosts
        ];
      };
    };

    # Ptyxis terminal emulator (GNOME)
    programs.ptyxis = {
      enable = true;
    };

    # Enable ghostty daemon for faster startup
    # Link the service file from the ghostty package to enable it declaratively
    # Use graphical-session.target so it only starts in graphical sessions
    xdg.configFile."systemd/user/graphical-session.target.wants/app-com.mitchellh.ghostty.service".source =
      "${pkgs.ghostty}/lib/systemd/user/app-com.mitchellh.ghostty.service";
  };
}
