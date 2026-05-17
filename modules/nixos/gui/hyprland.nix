{
  config,
  lib,
  ...
}:
let
  cfg = config.nixconfig.hyprland;
in
{
  options.nixconfig.hyprland = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Enable Hyprland Wayland compositor with UWSM.
        Works with any display manager or bare framebuffer.
        Package and portal package are set automatically by the upstream
        Hyprland flake NixOS module (hyprland.nixosModules.default in flake.nix).
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    programs.hyprland = {
      enable = true;
      withUWSM = true;
    };

    # Binary cache for Hyprland upstream flake builds.
    # Must NOT set hyprland.inputs.nixpkgs.follows in flake.nix — doing so
    # would rebuild against a different nixpkgs and break cache alignment.
    nix.settings = {
      substituters = lib.mkAfter [ "https://hyprland.cachix.org" ];
      trusted-public-keys = lib.mkAfter [
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      ];
    };
  };
}
