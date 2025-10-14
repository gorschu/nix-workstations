{ config, ... }:
{
  # Configure sops for home-manager
  # The age key should exist at ~/.config/sops/age/keys.txt
  sops.age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";

  # Ensure sops directory exists and keys stay safe
  systemd.user.tmpfiles.rules = [
    "d %h/.config/sops 0700 - - -"
    "d %h/.config/sops/age 0700 - - -"
    "z %h/.config/sops/age/keys.txt 0600 - - -" # Enforce permissions on age key
  ];
}
