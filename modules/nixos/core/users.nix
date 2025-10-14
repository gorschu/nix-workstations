# List of users for nixos system and their top-level configuration.
{
  inputs,
  lib,
  config,
  ...
}:
let
  inherit (inputs) self;
  mapListToAttrs =
    m: f:
    lib.listToAttrs (
      map (name: {
        inherit name;
        value = f name;
      }) m
    );
in
{
  options = {
    myusers = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      description = "List of usernames";
      defaultText = "All users under ./configuration/users are included by default";
      default =
        let
          dirContents = builtins.readDir (self + /configurations/home);
          fileNames = builtins.attrNames dirContents; # Extracts keys: [ "gorschu.nix" ]
          regularFiles = builtins.filter (name: dirContents.${name} == "regular") fileNames; # Filters for regular files
          baseNames = map (name: builtins.replaceStrings [ ".nix" ] [ "" ] name) regularFiles; # Removes .nix extension
        in
        baseNames;
    };

    rootSshKeys = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "SSH public keys to authorize for root user";
    };
  };

  config = {
    # Home-manager integration settings
    home-manager = {
      useGlobalPkgs = true; # Use system pkgs, saves evaluation
      useUserPackages = true; # Install to /etc/profiles/per-user

      # Enable home-manager for our users
      users = mapListToAttrs config.myusers (name: {
        imports = [ (self + /configurations/home/${name}.nix) ];
      });
    };

    # For home-manager to work.
    # https://github.com/nix-community/home-manager/issues/4026#issuecomment-1565487545
    users = {
      users =
        (mapListToAttrs config.myusers (name: {
          isNormalUser = true;
          group = name;
          extraGroups = [
            "wheel"
            "networkmanager"
            "video"
            "audio"
          ];
          openssh.authorizedKeys.keys = config.home-manager.users.${name}.me.sshKeys or [ ];
        }))
        // {
          # Root SSH keys
          root.openssh.authorizedKeys.keys = config.rootSshKeys;
        };

      # Create per-user groups
      groups = mapListToAttrs config.myusers (_name: { });
    };

    # All users can add Nix caches.
    nix.settings.trusted-users = [
      "root"
    ]
    ++ config.myusers;
  };
}
