{ config, lib, ... }:
let
  cfg = config.nixconfig.containers;
in
{
  options.nixconfig.containers = {
    enable = lib.mkEnableOption "container tooling";

    podman = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = cfg.enable;
        defaultText = lib.literalExpression "config.nixconfig.containers.enable";
        description = "Enable Podman when container tooling is enabled.";
      };

      storage.enable = lib.mkOption {
        type = lib.types.bool;
        default = cfg.podman.enable;
        defaultText = lib.literalExpression "config.nixconfig.containers.podman.enable";
        description = "Enable dedicated rootless Podman storage bind mounts.";
      };
    };

    distrobox.enable = lib.mkOption {
      type = lib.types.bool;
      default = cfg.podman.enable;
      defaultText = lib.literalExpression "config.nixconfig.containers.podman.enable";
      description = "Install Distrobox when Podman is enabled.";
    };

    rootlessUsers = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = config.myusers;
      defaultText = lib.literalExpression "config.myusers";
      description = "Users whose rootless Podman storage is backed by dedicated container storage.";
    };
  };

  config = lib.mkIf cfg.enable {
    nixconfig.podman = {
      enable = lib.mkDefault cfg.podman.enable;
      storage = {
        enable = lib.mkDefault cfg.podman.storage.enable;
        rootlessUsers = lib.mkDefault cfg.rootlessUsers;
      };
    };

    nixconfig.distrobox.enable = lib.mkDefault cfg.distrobox.enable;
  };
}
