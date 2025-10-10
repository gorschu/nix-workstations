{ flake, ... }:
let
  inherit (flake) inputs;
  inherit (inputs) self;
in
{
  imports = [
    self.homeModules.default
  ];

  # Enable GUI modules for this user
  homeconfig.gui.enable = true;

  # Defined by /modules/home/me.nix
  # And used all around in /modules/home/*
  me = {
    username = "gorschu";
    fullname = "Gordon Schulz";
    email = "gordon@gordonschulz.de";
    sshKeys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMUkEk7GV/qWMR9SJFYSJSxwnPxR8fG2Fn9VILHcyPYQ gorschu@general"
    ];
  };

  home.stateVersion = "25.11";
}
