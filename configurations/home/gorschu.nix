{ inputs, ... }:
{
  imports = [
    inputs.self.homeModules.default
  ];

  # Enable GUI modules for this user
  homeconfig.gui.enable = true;
  homeconfig.gui.plasma.enable = true;
  homeconfig.gui.noctalia.enable = true;
  homeconfig.gui.vicinae.enable = true;
  homeconfig.gui.hypridle.enable = true;

  # SSH configuration
  homeconfig.cli.ssh = {
    secretConfigs = [ "personal" ]; # Add "work" when you have it
    keys = [ "ssh-key-seedbox_ed25519" ]; # Your test key
  };

  # Defined by /modules/home/me.nix
  # And used all around in /modules/home/*
  me = {
    username = "gorschu";
    fullname = "Gordon Schulz";
    email = "gordon@gordonschulz.de";
    gpgSigningKey = "0A47650A15E4F0F4003EC450DEE550054AA972F6";
    gpgPublicKeyFile = ./gorschu.gpg.asc;
    sshKeys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMUkEk7GV/qWMR9SJFYSJSxwnPxR8fG2Fn9VILHcyPYQ gorschu@general"
    ];
  };

  home.stateVersion = "26.05";
}
