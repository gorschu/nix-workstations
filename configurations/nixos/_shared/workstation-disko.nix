{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              priority = 1;
              name = "ESP";
              size = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                extraArgs = [
                  "-n"
                  "ESP"
                ];
                mountpoint = "/boot";
                mountOptions = [
                  "defaults"
                  "nofail"
                  "umask=0077"
                ];
              };
            };
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "zroot";
              };
            };
          };
        };
      };
    };
    zpool = {
      zroot = {
        type = "zpool";
        rootFsOptions = {
          mountpoint = "none";
          compression = "zstd";
          acltype = "posixacl";
          xattr = "sa";
        };
        options.ashift = "12";
        datasets = {
          # Encrypted root - all children inherit encryption.
          # `just install` writes the passphrase to /tmp/zfs-passphrase on the
          # target via nixos-anywhere --disk-encryption-keys, so disko can
          # create the dataset non-interactively. Immediately after creation
          # we flip keylocation back to prompt so subsequent boots ask for it.
          "encrypted" = {
            type = "zfs_fs";
            options = {
              encryption = "aes-256-gcm";
              keyformat = "passphrase";
              keylocation = "file:///tmp/zfs-passphrase";
              canmount = "off";
              mountpoint = "none";
            };
            postCreateHook = "zfs set keylocation=prompt zroot/encrypted";
          };

          # Ephemeral datasets (wiped on boot for impermanence)
          "encrypted/ephemeral" = {
            type = "zfs_fs";
            options = {
              canmount = "off";
              mountpoint = "none";
            };
          };
          "encrypted/ephemeral/swap" = {
            type = "zfs_volume";
            size = "8G";
            options = {
              volblocksize = "4096";
              sync = "always"; # safe for swap on ZFS
              primarycache = "metadata"; # don't cache swap pages in ARC
              secondarycache = "none";
              compression = "zle"; # only compress zero pages; zswap handles the rest
            };
            content.type = "swap";
          };
          "encrypted/ephemeral/root" = {
            type = "zfs_fs";
            mountpoint = "/";
            postCreateHook = "zfs list -t snapshot -H -o name | grep -E '^zroot/encrypted/ephemeral/root@blank$' || zfs snapshot zroot/encrypted/ephemeral/root@blank";
          };
          "encrypted/ephemeral/tmp" = {
            type = "zfs_fs";
            mountpoint = "/tmp";
            options = {
              quota = "32G";
              sync = "disabled";
              redundant_metadata = "none";
            };
          };

          # Safe/persistent datasets (survives reboot, backed up)
          "encrypted/safe" = {
            type = "zfs_fs";
            options = {
              canmount = "off";
              mountpoint = "none";
            };
          };
          "encrypted/safe/home" = {
            type = "zfs_fs";
            mountpoint = "/home";
          };
          "encrypted/safe/nix" = {
            type = "zfs_fs";
            mountpoint = "/nix";
            options.atime = "off";
          };
          "encrypted/safe/persist" = {
            type = "zfs_fs";
            mountpoint = "/persist";
          };
          "encrypted/safe/var-log" = {
            type = "zfs_fs";
            mountpoint = "/var/log";
            options.quota = "10G";
          };
          "encrypted/safe/cache" = {
            type = "zfs_fs";
            mountpoint = "/var/cache";
            options.quota = "20G";
          };

          # Container storage: dedicated subtree so podman/distrobox doesn't
          # share recordsize/atime with /home, and so it can be excluded from
          # backups in one rule. Tuning lives on the parent; children inherit.
          "encrypted/safe/containers" = {
            type = "zfs_fs";
            options = {
              canmount = "off";
              mountpoint = "none";
              acltype = "posixacl";
              xattr = "sa";
              compression = "zstd";
              atime = "off";
              recordsize = "128K";
            };
          };
          # Rootful graphroot mounted at podman's default path
          "encrypted/safe/containers/storage" = {
            type = "zfs_fs";
            mountpoint = "/var/lib/containers/storage";
          };
          # Per-user rootless graphroots, bind-mounted into ~/.local/share/containers
          # by modules/nixos/virt/podman-storage.nix
          "encrypted/safe/containers/users" = {
            type = "zfs_fs";
            options = {
              canmount = "off";
              mountpoint = "none";
            };
          };
          "encrypted/safe/containers/users/gorschu" = {
            type = "zfs_fs";
            mountpoint = "/var/lib/containers/users/gorschu";
          };

          # VM disk images: recordsize=64K matches qcow2's default cluster_size
          # to avoid read-modify-write amplification on small VM writes. Quota
          # caps runaway VMs so they can't eat the root pool.
          "encrypted/safe/libvirt" = {
            type = "zfs_fs";
            options = {
              canmount = "off";
              mountpoint = "none";
              compression = "zstd";
              atime = "off";
              recordsize = "64K";
            };
          };
          "encrypted/safe/libvirt/images" = {
            type = "zfs_fs";
            mountpoint = "/var/lib/libvirt/images";
            options.quota = "200G";
          };
        };
      };
    };
  };
}
