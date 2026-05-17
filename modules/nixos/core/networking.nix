{
  config,
  lib,
  inputs,
  ...
}:
let
  inherit (inputs) self;
  cfg = config.nixconfig.networking;
in
{
  options.nixconfig.networking = {
    enable = lib.mkEnableOption "personal WiFi profiles and NetworkManager setup";

    waitOnline = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Wait for network to be fully online before boot completes (useful for servers, disable for laptops)";
    };
  };

  config = lib.mkIf cfg.enable {
    networking = {
      networkmanager.enable = true;

      # Pre-configured WiFi networks with sops-encrypted passwords
      networkmanager.ensureProfiles = {
        environmentFiles = [
          config.sops.templates."wifi-env".path
        ];
        profiles = {
          "home" = {
            connection = {
              id = "home";
              type = "wifi";
              autoconnect = true;
            };
            wifi = {
              ssid = "GoBa Packet Loss";
              mode = "infrastructure";
            };
            wifi-security = {
              key-mgmt = "wpa-psk";
              psk = "$WIFI_PASSWORD_HOME"; # Replaced from sops secret
            };
            ipv4.method = "auto";
            ipv6.method = "auto";
          };
          "altenhof" = {
            connection = {
              id = "altenhof";
              type = "wifi";
              autoconnect = true;
            };
            wifi = {
              ssid = "FritzBoxJH";
              mode = "infrastructure";
            };
            wifi-security = {
              key-mgmt = "wpa-psk";
              psk = "$WIFI_PASSWORD_ALTENHOF"; # Replaced from sops secret
            };
            ipv4.method = "auto";
            ipv6.method = "auto";
          };
          "travel" = {
            connection = {
              id = "travel";
              type = "wifi";
              autoconnect = true;
            };
            wifi = {
              ssid = "FBI Surveillance Van";
              mode = "infrastructure";
            };
            wifi-security = {
              key-mgmt = "wpa-psk";
              psk = "$WIFI_PASSWORD_TRAVEL"; # Replaced from sops secret
            };
            ipv4.method = "auto";
            ipv6.method = "auto";
          };
        };
      };
    };

    # Disable for laptops (may have disconnected ethernet interfaces)
    # Enable for servers (need network for services)
    systemd.services.NetworkManager-wait-online.enable = cfg.waitOnline;

    # Sops secrets for WiFi passwords
    sops = {
      templates."wifi-env" = {
        content = ''
          WIFI_PASSWORD_HOME=${config.sops.placeholder."wifi-password-home"}
          WIFI_PASSWORD_ALTENHOF=${config.sops.placeholder."wifi-password-altenhof"}
          WIFI_PASSWORD_TRAVEL=${config.sops.placeholder."wifi-password-travel"}
        '';
      };

      secrets = {
        "wifi-password-home" = {
          sopsFile = self + /secrets/hosts/wifi.yaml;
          key = "password-home";
        };
        "wifi-password-altenhof" = {
          sopsFile = self + /secrets/hosts/wifi.yaml;
          key = "password-altenhof";
        };
        "wifi-password-travel" = {
          sopsFile = self + /secrets/hosts/wifi.yaml;
          key = "password-travel";
        };
      };
    };
  };
}
