{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.nixconfig.storage.impermanence;

  absolutePath = lib.types.strMatching "^/.*";
  rootPool = builtins.head (lib.splitString "/" cfg.rootDataset);
  tailscaleEnabled = config.nixconfig.networking.tailscale.enable or false;
  bluetoothEnabled = config.hardware.bluetooth.enable or false;

  defaultFiles = [
    "/etc/machine-id"
  ];

  defaultDirectories = [
    "/var/lib/nixos"
    "/var/lib/systemd"
  ]
  ++ lib.optional tailscaleEnabled "/var/lib/tailscale"
  ++ lib.optional bluetoothEnabled "/var/lib/bluetooth";

  defaultReasons = {
    "/etc/machine-id" = "Stable machine identity across impermanent root resets.";
    "/var/lib/nixos" = "NixOS runtime state that must remain stable across root resets.";
    "/var/lib/systemd" = "Systemd state for persistent timers and service bookkeeping.";
    "networking.hostId" = "Deterministic ZFS import host identity derived from the hostname.";
  }
  // lib.optionalAttrs tailscaleEnabled {
    "/var/lib/tailscale" = "Tailscale node identity and enrollment state for enabled hosts.";
  }
  // lib.optionalAttrs bluetoothEnabled {
    "/var/lib/bluetooth" = "Bluetooth pairing state for hosts with Bluetooth enabled.";
  };

  reviewedKeys =
    cfg.systemState.files ++ cfg.systemState.directories ++ lib.attrNames cfg.systemState.evaluated;

  missingReasonKeys = builtins.filter (
    key: !(lib.hasAttr key cfg.systemState.reasons) || cfg.systemState.reasons.${key} == ""
  ) reviewedKeys;

  nonAbsoluteSystemPaths = builtins.filter (path: !(lib.hasPrefix "/" path)) (
    cfg.systemState.files ++ cfg.systemState.directories ++ cfg.systemState.backupPaths
  );

  backingPath = path: "${cfg.persistRoot}${path}";
  reviewedBackingPaths = map backingPath (cfg.systemState.files ++ cfg.systemState.directories);
  unreviewedBackupPaths = builtins.filter (
    path: !(builtins.elem path reviewedBackingPaths)
  ) cfg.systemState.backupPaths;

  requiredBackingFileChecks = lib.concatMapStringsSep "\n" (path: ''
    if ! test -e ${lib.escapeShellArg (backingPath path)}; then
      echo "impermanence: missing persistent backing file ${backingPath path} for ${path}" >&2
      exit 1
    fi
  '') cfg.systemState.files;

  requiredBackingDirectoryChecks = lib.concatMapStringsSep "\n" (path: ''
    if ! test -d ${lib.escapeShellArg (backingPath path)}; then
      echo "impermanence: missing persistent backing directory ${backingPath path} for ${path}" >&2
      exit 1
    fi
  '') cfg.systemState.directories;

  shellRootDataset = lib.escapeShellArg cfg.rootDataset;
  shellBlankSnapshot = lib.escapeShellArg cfg.blankSnapshot;
  shellPersistRoot = lib.escapeShellArg cfg.persistRoot;
  shellSafeHavenRoot = lib.escapeShellArg cfg.userSafeHavenRoot;
in
{
  options.nixconfig.storage.impermanence = {
    enable = lib.mkEnableOption "impermanent root with reviewed persistent state";

    rootDataset = lib.mkOption {
      type = lib.types.str;
      default = "zroot/encrypted/ephemeral/root";
      description = "ZFS dataset mounted as / and rolled back to a blank snapshot on boot.";
    };

    blankSnapshot = lib.mkOption {
      type = lib.types.str;
      default = "zroot/encrypted/ephemeral/root@blank";
      description = "Clean root snapshot used as the boot-time rollback point.";
    };

    persistRoot = lib.mkOption {
      type = absolutePath;
      default = "/persist";
      description = "Persistent root used by impermanence for system state.";
    };

    userSafeHavenRoot = lib.mkOption {
      type = absolutePath;
      default = "/persist/home";
      description = "Parent path for per-user curated safe-haven data.";
    };

    systemState = {
      files = lib.mkOption {
        type = lib.types.listOf absolutePath;
        default = defaultFiles;
        description = "Root-owned files that must survive root reset.";
      };

      directories = lib.mkOption {
        type = lib.types.listOf absolutePath;
        default = defaultDirectories;
        description = "Root-owned directories that must survive root reset.";
      };

      reasons = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = defaultReasons;
        description = "Audit reasons keyed by persisted path or evaluated-state key.";
      };

      evaluated = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = {
          "networking.hostId" = config.networking.hostId;
        };
        description = "Declarative evaluated values that satisfy system-state requirements.";
      };

      backupPaths = lib.mkOption {
        type = lib.types.listOf absolutePath;
        default = [ ];
        description = "Persisted system-state backing paths that should also be restic sources.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.rootDataset != "";
        message = "nixconfig.storage.impermanence.rootDataset must not be empty.";
      }
      {
        assertion = cfg.blankSnapshot != "";
        message = "nixconfig.storage.impermanence.blankSnapshot must not be empty.";
      }
      {
        assertion = lib.hasPrefix "${cfg.rootDataset}@" cfg.blankSnapshot;
        message = "nixconfig.storage.impermanence.blankSnapshot must belong to rootDataset.";
      }
      {
        assertion = !(lib.hasPrefix "/home/" cfg.userSafeHavenRoot);
        message = "nixconfig.storage.impermanence.userSafeHavenRoot must not live inside /home.";
      }
      {
        assertion = missingReasonKeys == [ ];
        message = ''
          nixconfig.storage.impermanence.systemState.reasons is missing non-empty reasons for:
          ${lib.concatStringsSep ", " missingReasonKeys}
        '';
      }
      {
        assertion = nonAbsoluteSystemPaths == [ ];
        message = ''
          Impermanence system-state paths and backup paths must be absolute:
          ${lib.concatStringsSep ", " nonAbsoluteSystemPaths}
        '';
      }
      {
        assertion = unreviewedBackupPaths == [ ];
        message = ''
          nixconfig.storage.impermanence.systemState.backupPaths may only include reviewed
          persistent backing paths: ${lib.concatStringsSep ", " unreviewedBackupPaths}
        '';
      }
    ];

    boot.initrd.systemd.services.impermanence-root-rollback = {
      description = "Roll back impermanent root dataset to blank snapshot";
      after = [ "zfs-import-${rootPool}.service" ];
      before = [ "sysroot.mount" ];
      requiredBy = [ "sysroot.mount" ];
      unitConfig = {
        ConditionPathExists = "!/run/impermanence-root-rollback.done";
        DefaultDependencies = "no";
      };
      serviceConfig = {
        RemainAfterExit = true;
        Type = "oneshot";
      };
      path = [ config.boot.zfs.package ];
      script = ''
        echo "impermanence: verifying ${cfg.blankSnapshot}"
        if ! zfs list -H -t snapshot -o name ${shellBlankSnapshot} >/dev/null 2>&1; then
          echo "impermanence: missing required root snapshot ${cfg.blankSnapshot}" >&2
          exit 1
        fi

        echo "impermanence: rolling back ${cfg.rootDataset} to ${cfg.blankSnapshot}"
        zfs rollback -r ${shellBlankSnapshot}
        : > /run/impermanence-root-rollback.done
      '';
    };

    environment.persistence.${cfg.persistRoot} = {
      directories = cfg.systemState.directories;
      files = cfg.systemState.files;
    };

    fileSystems.${cfg.persistRoot}.neededForBoot = true;
    fileSystems."/home".neededForBoot = true;

    system.activationScripts.impermanenceReadiness = {
      deps = [ "persist-files" ];
      text = ''
        set -eu

        if ! ${pkgs.zfs}/bin/zfs list -H -o name ${shellRootDataset} >/dev/null 2>&1; then
          echo "impermanence: missing required root dataset ${cfg.rootDataset}" >&2
          exit 1
        fi

        if ! ${pkgs.zfs}/bin/zfs list -H -t snapshot -o name ${shellBlankSnapshot} >/dev/null 2>&1; then
          echo "impermanence: missing required root snapshot ${cfg.blankSnapshot}" >&2
          exit 1
        fi

        test -d ${shellPersistRoot} || {
          echo "impermanence: missing persistent root ${cfg.persistRoot}" >&2
          exit 1
        }

        test -d /home || {
          echo "impermanence: missing persistent /home" >&2
          exit 1
        }

        ${requiredBackingFileChecks}
        ${requiredBackingDirectoryChecks}

        install -d -m 0755 -o root -g root ${shellSafeHavenRoot}
      '';
    };
  };
}
