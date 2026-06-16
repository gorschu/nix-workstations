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
    # The store root is 0701, not 0700: distrobox runs containers with
    # `--userns keep-id`, under which crun resolves paths as a shifted,
    # non-owner uid. That uid traverses the user's 0700 home fine (same
    # filesystem, maps as owner) but gets EACCES the moment it crosses the
    # mount-point boundary into this bind-mounted dataset, which crun reports
    # as the bogus `crun: readlink ``: No such file or directory`. o+x on the
    # mount-point root lets it cross; deeper dirs stay 0700 (traversed as the
    # mapped owner). Both rules below resolve to the same dataset-root inode
    # once the bind mount is active, so both must carry o+x or the second
    # reverts the first.
    systemd.tmpfiles.rules =
      [ "d /var/lib/containers/users 0755 root root - -" ]
      ++ lib.concatMap (user: [
        "d /var/lib/containers/users/${user} 0701 ${user} users - -"
        "d /home/${user}/.local 0755 ${user} users - -"
        "d /home/${user}/.local/share 0755 ${user} users - -"
        "d /home/${user}/.local/share/containers 0701 ${user} users - -"
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
