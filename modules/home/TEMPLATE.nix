# Module name and description
# Template for home-manager modules following the two-level enable pattern
{
  config,
  lib,
  pkgs,
  ...
}:
let
  # Reference the category-level config: homeconfig.cli or homeconfig.gui
  cfg = config.homeconfig.cli; # Change to .gui for GUI modules
in
{
  # ============================================================================
  # OPTIONS (optional - only if this module needs its own configuration)
  # ============================================================================

  # For inline options in individual modules:
  options.homeconfig.cli.mycategory.myoption = lib.mkOption {
    type = lib.types.str;
    default = "value";
    description = "Description of this option";
  };

  # For subcategory enable options, add to options.nix instead:
  # modules/home/cli/options.nix or modules/home/gui/options.nix

  # ============================================================================
  # CONFIGURATION
  # ============================================================================

  # Configuration wrapped in mkIf checking BOTH category and subcategory
  # This is the REQUIRED pattern: cfg.enable && cfg.subcategory.enable
  config = lib.mkIf (cfg.enable && cfg.mycategory.enable) {

    # Install packages
    home.packages = with pkgs; [
      mypackage
    ];

    # Configure programs
    programs.myprogram = {
      enable = true;
      # configuration here
    };

    # Use config.me.* for user metadata:
    # - config.me.username  (system username)
    # - config.me.fullname  (full name for Git, etc.)
    # - config.me.email     (email address)
    # - config.me.sshKeys   (SSH public keys list)

    # Set environment variables
    home.sessionVariables = {
      MY_VAR = "value";
    };

    # XDG configuration files
    xdg.configFile."myapp/config".text = ''
      # configuration content
    '';
  };
}
