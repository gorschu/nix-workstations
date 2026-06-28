{
  lib,
  osConfig ? null,
  ...
}:
let
  nixosGuiEnabled = osConfig != null && (osConfig.nixconfig.gui.enable or false);
  nixosHyprlandEnabled = osConfig != null && (osConfig.nixconfig.hyprland.enable or false);
  nixosPlasmaEnabled = osConfig != null && (osConfig.nixconfig.plasma.enable or false);
  guiDefault = if osConfig == null then false else nixosGuiEnabled;
  hyprlandDefault = if osConfig == null then false else nixosHyprlandEnabled;
  plasmaDefault = if osConfig == null then false else nixosPlasmaEnabled;
in
{
  # Two-level enable pattern:
  # 1. Category level (homeconfig.gui.enable) - master switch for all GUI
  # 2. Subcategory level (homeconfig.gui.browsers.enable) - fine-grained control
  # Individual modules check: cfg.enable && cfg.subcategory.enable

  options.homeconfig.gui = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = guiDefault;
      defaultText = lib.literalExpression ''
        if osConfig != null then osConfig.nixconfig.gui.enable else false
      '';
      description = ''
        Enable Home Manager GUI modules.

        On NixOS this follows nixconfig.gui.enable by default. For standalone
        Home Manager profiles it defaults to false and must be enabled
        explicitly.
      '';
    };

    browsers = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable web browsers (firefox, etc.)";
      };
    };

    fonts = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable font configuration and substitutions";
      };
    };

    catppuccin = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable Catppuccin theme defaults";
      };
    };

    terminals = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable terminal emulator configuration (kitty)";
      };
    };

    desktop = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable desktop integration (XDG portals, MIME associations)";
      };
    };

    hyprland = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = hyprlandDefault;
        defaultText = lib.literalExpression ''
          if osConfig != null then osConfig.nixconfig.hyprland.enable else false
        '';
        description = ''
          Enable the Home Manager side of the Hyprland session stack.

          On NixOS this follows nixconfig.hyprland.enable by default. For
          standalone Home Manager profiles it defaults to false and must be
          enabled explicitly.
        '';
      };

      noctalia = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable Noctalia integration inside the Hyprland session.";
        };
      };

      vicinae = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable Vicinae integration inside the Hyprland session.";
        };
      };

      hypridle = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable Hyprland idle handling via hypridle.";
        };
      };
    };

    plasma = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = plasmaDefault;
        defaultText = lib.literalExpression ''
          if osConfig != null then osConfig.nixconfig.plasma.enable else false
        '';
        description = ''
          Enable KDE Plasma declarative user configuration via plasma-manager.

          On NixOS this follows nixconfig.plasma.enable by default. For standalone
          Home Manager profiles it defaults to false and must be enabled
          explicitly.
        '';
      };
    };
  };
}
