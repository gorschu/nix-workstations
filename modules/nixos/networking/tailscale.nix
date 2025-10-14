{
  config,
  lib,
  inputs,
  ...
}:
let
  inherit (inputs) self;
  cfg = config.nixconfig.networking.tailscale;
in
{
  options.nixconfig.networking.tailscale = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Tailscale VPN";
    };

    autoconnect = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Automatically connect using auth key from SOPS";
    };
  };

  config = lib.mkIf cfg.enable {
    # Enable Tailscale service
    services.tailscale = {
      enable = true;
      openFirewall = true;
      authKeyFile = lib.mkIf cfg.autoconnect config.sops.secrets."tailscale-auth-key".path;
    };

    # Loose reverse path filtering for Tailscale
    networking.firewall.checkReversePath = "loose";

    # SOPS secret for Tailscale auth key (if using auto-connect)
    sops.secrets."tailscale-auth-key" = lib.mkIf cfg.autoconnect {
      sopsFile = self + /secrets/hosts/${config.networking.hostName}/tailscale.yaml;
    };
  };
}
