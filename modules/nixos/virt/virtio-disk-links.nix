{ config, lib, ... }:
let
  cfg = config.nixconfig.virt.virtioDiskLinks;

  # Udev rules for creating stable virtio disk links
  virtioUdevRules = ''
    # Create by-id links for virtio block devices based on PCI slot
    SUBSYSTEM=="block", KERNEL=="vd*", ATTRS{serial}=="?*", SYMLINK+="disk/by-id/virtio-$attr{serial}"
    SUBSYSTEM=="block", KERNEL=="vd*[0-9]", ATTRS{serial}=="?*", SYMLINK+="disk/by-id/virtio-$attr{serial}-part%n"

    # Fallback: create links based on virtio index if no serial
    SUBSYSTEM=="block", KERNEL=="vda", SYMLINK+="disk/by-id/virtio-boot-disk"
    SUBSYSTEM=="block", KERNEL=="vda[0-9]", SYMLINK+="disk/by-id/virtio-boot-disk-part%n"
  '';
in
{
  options.nixconfig.virt.virtioDiskLinks = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Create stable /dev/disk/by-id/ links for virtio block devices";
    };
  };

  config = lib.mkIf cfg.enable {
    services.udev.extraRules = virtioUdevRules;
    boot.initrd.services.udev.rules = virtioUdevRules;
  };
}
