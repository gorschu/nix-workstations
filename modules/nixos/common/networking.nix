{
  config,
  flake,
  ...
}:
let
  inherit (flake.inputs) self;
in
{
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
            psk = "$WIFI_HOME_PASSWORD"; # Replaced from sops secret
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
            psk = "$WIFI_TRAVEL_PASSWORD"; # Replaced from sops secret
          };
          ipv4.method = "auto";
          ipv6.method = "auto";
        };
      };
    };
  };

  # Sops secrets for WiFi passwords
  sops = {
    templates."wifi-env" = {
      content = ''
        WIFI_HOME_PASSWORD=${config.sops.placeholder."wifi-home-password"}
        WIFI_TRAVEL_PASSWORD=${config.sops.placeholder."wifi-travel-password"}
      '';
    };

    secrets."wifi-home-password" = {
      sopsFile = self + /secrets/wifi.yaml;
      key = "home-password";
    };
    secrets."wifi-travel-password" = {
      sopsFile = self + /secrets/wifi.yaml;
      key = "travel-password";
    };
  };
}
