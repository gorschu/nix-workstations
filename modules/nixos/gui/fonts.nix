{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.nixconfig.gui.fonts;
in
{
  options.nixconfig.gui.fonts = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable font configuration";
    };
  };

  config = lib.mkIf cfg.enable {
    # Install fonts system-wide
    fonts.packages = with pkgs; [
      # Nerd Fonts for terminal/coding
      nerd-fonts.jetbrains-mono
      nerd-fonts.monaspace

      # Adobe Source fonts for system UI
      source-sans
      source-serif

      # GNOME Adwaita fonts
      adwaita-fonts
    ];

    # Font configuration for modern displays with excellent readability
    fonts.fontconfig = {
      enable = true;

      # Antialiasing for smooth font edges
      antialias = true;

      # Hinting adjusts font outlines to pixel grid for sharpness
      hinting = {
        enable = true;
        # "slight" is best for modern high-DPI displays
        # Options: none, slight, medium, full
        style = "slight";
        autohint = false;
      };

      # Subpixel rendering uses RGB subpixels for sharper text
      # Only enable if you have an RGB LCD (most modern displays)
      subpixel = {
        rgba = "rgb"; # RGB subpixel order (use "bgr" for some displays)
        lcdfilter = "default"; # Reduces color fringing
      };

      # Default fonts for different categories
      defaultFonts = {
        serif = [
          "Source Serif 4"
          "Source Serif Pro"
        ];
        sansSerif = [
          "Source Sans 3"
          "Source Sans Pro"
        ];
        monospace = [
          "Adwaita Mono"
          "JetBrainsMono Nerd Font"
        ];
        emoji = [ "Noto Color Emoji" ];
      };
    };
  };
}
