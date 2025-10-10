{ lib, ... }:
{
  # Two-level enable pattern:
  # 1. Category level (homeconfig.cli.enable) - master switch for all CLI
  # 2. Subcategory level (homeconfig.cli.development.enable) - fine-grained control
  # Individual modules check: cfg.enable && cfg.subcategory.enable

  options.homeconfig.cli = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable all CLI modules";
    };

    development = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable development tools (git, direnv, nix-index, ai-agents)";
      };
    };

    editor = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable neovim editor";
      };
    };

    shell = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable shell configuration and terminal emulators";
      };
    };

    system = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable core system configuration (XDG, gc, nix, packages, user info)";
      };
    };
  };
}
