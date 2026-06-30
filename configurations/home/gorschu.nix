{ config, inputs, ... }:
{
  imports = [
    inputs.self.homeModules.default
  ];

  # SSH configuration
  homeconfig.cli.ssh = {
    secretConfigs = [ "personal" ]; # Add "work" when you have it
    keys = [ "ssh-key-seedbox_ed25519" ]; # Your test key
  };

  homeconfig.cli.cloud = {
    enable = true;
    remotes = {
      gdrive = {
        type = "drive";
        settings = {
          scope = "drive";
          fast_list = true;
          chunk_size = "32M";
        };
        secrets = {
          client_id = "gdrive/client_id";
          client_secret = "gdrive/client_secret";
          root_folder_id = "gdrive/root_folder_id";
        };
      };

      dropbox = {
        type = "dropbox";
        settings.fast_list = true;
      };

      ocis = {
        type = "webdav";
        settings = {
          url = "https://ocis.gobagreven.de/dav/spaces/91df2cf2-8885-4867-b602-475bd599282a$55d90393-9d28-4ce3-a3a1-85bd745e1b5d";
          vendor = "owncloud";
          user = config.me.username;
        };
        secrets.pass = "ocis/pass";
      };
    };
  };

  homeconfig.persistence.safeHaven.directories = [
    {
      path = "ImpermanenceTest";
      reason = "Validation directory for impermanence safe-haven exposure and reboot checks.";
    }
  ];

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
