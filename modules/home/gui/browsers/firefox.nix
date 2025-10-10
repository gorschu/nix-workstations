# Firefox browser configuration
# Template for home-manager GUI modules following the two-level enable pattern
{
  config,
  lib,
  pkgs,
  ...
}:
let
  # Reference the category-level config (cli or gui)
  cfg = config.homeconfig.gui;
in
{
  # Configuration wrapped in mkIf checking both category and subcategory
  # This is the required pattern: cfg.enable && cfg.subcategory.enable
  config = lib.mkIf (cfg.enable && cfg.browsers.enable) {
    # Enable native Wayland support for Firefox
    home.sessionVariables = {
      MOZ_ENABLE_WAYLAND = "1";
    };

    programs.firefox = {
      enable = true;

      package = pkgs.firefox;

      profiles.gorschu = {
        settings = {
          # Hardware acceleration
          "media.ffmpeg.vaapi.enabled" = true;
          "media.hardware-video-decoding.enabled" = true;
          "gfx.webrender.all" = true;

          # Wayland support
          "widget.use-xdg-desktop-portal.file-picker" = 1;

          # Performance
          "browser.cache.jsbc_compression_level" = 3;

          # Privacy (without breaking sites)
          "privacy.donottrackheader.enabled" = true;
          "privacy.trackingprotection.enabled" = true;

          # Disable annoyances
          "browser.newtabpage.activity-stream.showSponsored" = false;
          "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
          "extensions.pocket.enabled" = false;

          # Enable userChrome.css (for customization)
          "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
        };
      };
    };

    # Set as default browser
    xdg.mimeApps.defaultApplications = {
      "text/html" = "firefox.desktop";
      "x-scheme-handler/http" = "firefox.desktop";
      "x-scheme-handler/https" = "firefox.desktop";
      "x-scheme-handler/about" = "firefox.desktop";
      "x-scheme-handler/unknown" = "firefox.desktop";
    };
  };
}
