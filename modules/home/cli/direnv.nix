{
  config,
  lib,
  ...
}:
let
  cfg = config.homeconfig.cli;
in
{
  config = lib.mkIf (cfg.enable && cfg.development.enable) {
    # https://nixos.asia/en/direnv
    programs.direnv = {
      enable = true;
      enableBashIntegration = false;
      enableZshIntegration = true;
      nix-direnv = {
        enable = true;
      };
    };
  };
}
