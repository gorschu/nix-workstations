# User metadata module
# Defines core user information used across home-manager configuration
{ config, lib, ... }:
{
  options = {
    me = {
      username = lib.mkOption {
        type = lib.types.str;
        description = "Your username as shown by `id -un`";
      };
      fullname = lib.mkOption {
        type = lib.types.str;
        description = "Your full name for use in Git config";
      };
      email = lib.mkOption {
        type = lib.types.str;
        description = "Your email for use in Git config";
      };
      gpgSigningKey = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "OpenPGP signing key fingerprint for Git commits and tags.";
      };
      gpgPublicKeyFile = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = "Armored OpenPGP public key file matching gpgSigningKey.";
      };
      sshKeys = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "SSH public keys to authorize for this user";
      };
    };
  };

  config = {
    # Derive Home Manager's core identity fields from user metadata.
    home.username = config.me.username;
    home.homeDirectory = lib.mkDefault "/home/${config.me.username}";
  };
}
