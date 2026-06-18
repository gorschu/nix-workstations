{
  config,
  lib,
  pkgs,
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
    environment.systemPackages = with pkgs.kdePackages; [
      kwallet
      kwallet-pam
    ];

    programs.hyprland = {
      enable = true;
      withUWSM = true;
    };

    security.pam.services.login.kwallet = {
      enable = lib.mkDefault true;
      forceRun = lib.mkDefault true;
      package = lib.mkDefault pkgs.kdePackages.kwallet-pam;
    };
  };
}
