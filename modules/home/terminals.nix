{ pkgs, ... }:
{
  # Ghostty terminal emulator
  programs.ghostty = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    installBatSyntax = true;
    installVimSyntax = true;
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
}
