{ config, lib, ... }:
let
  cfg = config.nixconfig.virtio-disk-links;
in
{
  options.nixconfig.virtio-disk-links = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Create stable /dev/disk/by-id/ links for virtio block devices";
    };
  };

  config = lib.mkIf cfg.enable {
    # Create udev rules to generate stable disk links for virtio devices
    # This is needed because virtio devices don't have WWN/serial by default
    # and systemd needs persistent paths for encrypted device unlocking
    services.udev.extraRules = ''
      # Create by-id links for virtio block devices based on PCI slot
      SUBSYSTEM=="block", KERNEL=="vd*", ATTRS{serial}=="?*", SYMLINK+="disk/by-id/virtio-$attr{serial}"
      SUBSYSTEM=="block", KERNEL=="vd*[0-9]", ATTRS{serial}=="?*", SYMLINK+="disk/by-id/virtio-$attr{serial}-part%n"

      # Fallback: create links based on virtio index if no serial
      SUBSYSTEM=="block", KERNEL=="vda", SYMLINK+="disk/by-id/virtio-boot-disk"
      SUBSYSTEM=="block", KERNEL=="vda[0-9]", SYMLINK+="disk/by-id/virtio-boot-disk-part%n"
    '';

    # Ensure udev rules are processed early in boot for initrd
    boot.initrd.services.udev.rules = config.services.udev.extraRules;
  };
}
