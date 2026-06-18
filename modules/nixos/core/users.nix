# List of users for nixos system and their top-level configuration.
{
  inputs,
  lib,
  pkgs,
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
          regularFiles = builtins.filter (
            name: dirContents.${name} == "regular" && lib.hasSuffix ".nix" name
          ) fileNames;
          baseNames = map (lib.removeSuffix ".nix") regularFiles;
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
      backupFileExtension = "hm-backup";

      # Enable home-manager for our users
      users = mapListToAttrs config.myusers (name: {
        imports = [ (self + /configurations/home/${name}.nix) ];
      });
    };

    # For home-manager to work.
    # https://github.com/nix-community/home-manager/issues/4026#issuecomment-1565487545
    users = {
      mutableUsers = false;

      users =
        (mapListToAttrs config.myusers (name: {
          isNormalUser = true;
          group = name;
          shell = pkgs.zsh;
          extraGroups = [
            "wheel"
            "networkmanager"
            "video"
            "audio"
          ];
          openssh.authorizedKeys.keys = config.home-manager.users.${name}.me.sshKeys or [ ];
          hashedPasswordFile = config.sops.secrets."${name}/password".path;
        }))
        // {
          root = {
            openssh.authorizedKeys.keys = config.rootSshKeys;
            hashedPasswordFile = config.sops.secrets."root/password".path;
          };
        };

      # Create per-user groups
      groups = mapListToAttrs config.myusers (_name: { });
    };

    programs.zsh.enable = true;

    # All users can add Nix caches. @wheel covers sudoers.
    nix.settings.trusted-users = [
      "root"
      "@wheel"
    ]
    ++ config.myusers;

    sops.secrets = lib.mkMerge [
      # Per-user age keys: host SSH key bootstraps the user key for home-manager sops.
      # The -vm suffix is stripped so hephaestus-vm reuses hephaestus's key file.
      (lib.listToAttrs (
        map (name: {
          name = "${name}-age-key";
          value = {
            sopsFile =
              self + /secrets/users/${name}/age/${lib.removeSuffix "-vm" config.networking.hostName}.yaml;
            key = "age-key";
            owner = name;
            mode = "0400";
          };
        }) config.myusers
      ))
      # User passwords from the host secrets file
      (lib.listToAttrs (
        map (name: {
          name = "${name}/password";
          value = {
            sopsFile = self + /secrets/hosts/${config.networking.hostName}/users.yaml;
            neededForUsers = true;
          };
        }) config.myusers
      ))
      {
        "root/password" = {
          sopsFile = self + /secrets/hosts/${config.networking.hostName}/users.yaml;
          neededForUsers = true;
        };
      }
    ];
  };
}
