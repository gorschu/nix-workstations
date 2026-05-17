{ config, ... }:
{
  # Age key is provisioned at this path by NixOS sops-nix (running as root)
  # from secrets/users/<user>/age-key/<hostname>.yaml, encrypted for the host
  # SSH key. This means new hosts get the key automatically on first boot —
  # no manual copying needed.
  sops.age.keyFile = "/run/secrets/${config.home.username}-age-key";

  # Ensure sops directories exist with tight permissions for any manually
  # managed keys or future use.
  systemd.user.tmpfiles.rules = [
    "d %h/.config/sops 0700 - - -"
    "d %h/.config/sops/age 0700 - - -"
    "z %h/.config/sops/age/keys.txt 0600 - - -" # Enforce permissions on any manually placed key
  ];
}
