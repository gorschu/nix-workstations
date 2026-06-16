{ config, lib, ... }:
let
  cfg = config.nixconfig.podman.storage;
in
{
  options.nixconfig.podman.storage = {
    enable = lib.mkEnableOption "dedicated ZFS-backed container storage";

    rootlessUsers = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = ''
        Users whose rootless container store at
        ~/.local/share/containers is bind-mounted from
        /var/lib/containers/users/<user>.

        The backing dataset must exist (see workstation-disko.nix).
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.tmpfiles.rules =
      [ "d /var/lib/containers/users 0755 root root - -" ]
      ++ lib.concatMap (user: [
        "d /var/lib/containers/users/${user} 0700 ${user} users - -"
        "d /home/${user}/.local 0755 ${user} users - -"
        "d /home/${user}/.local/share 0755 ${user} users - -"
        "d /home/${user}/.local/share/containers 0700 ${user} users - -"
      ]) cfg.rootlessUsers;

    fileSystems = lib.listToAttrs (map (user: {
      name = "/home/${user}/.local/share/containers";
      value = {
        device = "/var/lib/containers/users/${user}";
        fsType = "none";
        options = [
          "bind"
          "x-systemd.requires-mounts-for=/var/lib/containers/users/${user}"
        ];
      };
    }) cfg.rootlessUsers);
  };
}
