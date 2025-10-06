{
  config,
  lib,
  pkgs,
  flake,
  ...
}:
let
  inherit (flake.inputs) self;
  cfg = config.nixconfig.restic-backup;

  # Target type definition
  targetType = lib.types.submodule (_: {
    options = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable this backup target";
      };

      repository = lib.mkOption {
        type = lib.types.str;
        description = "Repository URL (e.g., b2:bucket-name, s3:s3.amazonaws.com/bucket, /mnt/backup)";
      };

      backend = lib.mkOption {
        type = lib.types.enum [
          "b2"
          "s3"
          "local"
        ];
        default = "b2";
        description = "Backend type for credential handling (s3 works for AWS S3, Scaleway, and other S3-compatible providers)";
      };

      passwordFile = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Path to restic repository password file (defaults to SOPS secret path if null)";
      };

      timerConfig = lib.mkOption {
        type = lib.types.attrs;
        default = cfg.defaultTimerConfig;
        description = "Override default timer configuration for this target";
      };

      retention = lib.mkOption {
        type = lib.types.attrs;
        default = cfg.defaultRetention;
        description = "Override default retention policy for this target";
      };
    };
  });
in
{
  options.nixconfig.restic-backup = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable restic backups";
    };

    bucketName = lib.mkOption {
      type = lib.types.str;
      default = "gorschu-backup-workstations";
      description = "Bucket name for B2/S3 backups (can be shared across multiple hosts)";
    };

    paths = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "/home"
        "/etc"
        "/root"
      ];
      description = "Paths to backup (applies to all targets)";
    };

    exclude = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "/home/*/.cache"
        "/home/*/.local/share/Trash"
        "/home/*/Downloads"
        "/home/*/.mozilla/firefox/*/cache2"
        "/var/lib/systemd"
        "/var/lib/docker"
        "/var/lib/containers"
      ];
      description = "Paths to exclude from backup (applies to all targets)";
    };

    defaultTimerConfig = lib.mkOption {
      type = lib.types.attrs;
      default = {
        OnCalendar = "*-*-* 00/6:00:00"; # Every 6 hours
        RandomizedDelaySec = "30m";
        Persistent = true;
      };
      description = "Default timer configuration for all targets";
    };

    defaultRetention = lib.mkOption {
      type = lib.types.attrs;
      default = {
        keep-hourly = 16; # 4 days at 6h intervals
        keep-daily = 14; # 2 weeks
        keep-weekly = 8; # 2 months
        keep-monthly = 12; # 1 year
        keep-yearly = 3; # 3 years
      };
      description = "Default retention policy for all targets";
    };

    targets = lib.mkOption {
      type = lib.types.attrsOf targetType;
      default = { };
      description = "Backup targets configuration";
      example = lib.literalExpression ''
        {
          b2 = {
            repository = "b2:''${config.nixconfig.restic-backup.bucketName}:/backup-''${config.networking.hostName}";
            backend = "b2";
          };
          scaleway = {
            repository = "s3:s3.nl-ams.scw.cloud/''${config.nixconfig.restic-backup.bucketName}/backup-''${config.networking.hostName}";
            backend = "s3";  # Scaleway uses S3-compatible API
          };
          aws = {
            repository = "s3:s3.amazonaws.com/my-shared-bucket/backup-''${config.networking.hostName}";
            backend = "s3";
          };
        }
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # Install restic
    environment.systemPackages = [ pkgs.restic ];

    # Create backup service for each enabled target
    services.restic.backups = lib.mapAttrs (name: targetCfg: {
      inherit (targetCfg) repository;

      # Use provided passwordFile or default to SOPS secret path
      passwordFile =
        if targetCfg.passwordFile != null then
          targetCfg.passwordFile
        else
          config.sops.secrets."restic-${name}-password".path;

      # Environment file based on backend type
      environmentFile = config.sops.templates."restic-env-${name}".path;

      # Backup paths
      inherit (cfg) paths exclude;

      # Timer configuration
      inherit (targetCfg) timerConfig;

      # Retention and pruning
      pruneOpts = lib.mapAttrsToList (k: v: "--${k}=${toString v}") targetCfg.retention;

      # Post-backup message
      backupCleanupCommand = ''
        echo "Backup to ${name} completed successfully at $(date)"
      '';
    }) (lib.filterAttrs (_n: v: v.enable) cfg.targets);

    # SOPS environment templates for each target
    sops.templates = lib.mapAttrs' (
      name: targetCfg:
      lib.nameValuePair "restic-env-${name}" {
        content =
          if targetCfg.backend == "b2" then
            ''
              B2_ACCOUNT_ID=${config.sops.placeholder."restic-${name}-account-id"}
              B2_ACCOUNT_KEY=${config.sops.placeholder."restic-${name}-account-key"}
            ''
          else if targetCfg.backend == "s3" then
            ''
              AWS_ACCESS_KEY_ID=${config.sops.placeholder."restic-${name}-access-key-id"}
              AWS_SECRET_ACCESS_KEY=${config.sops.placeholder."restic-${name}-secret-access-key"}
            ''
          else
            ""; # local backend needs no credentials
      }
    ) (lib.filterAttrs (_n: v: v.enable) cfg.targets);

    # SOPS secrets for each target
    sops.secrets = lib.mkMerge (
      lib.mapAttrsToList (
        name: targetCfg:
        let
          secretsFile = self + /secrets/hosts/${config.networking.hostName}/restic.yaml;
        in
        {
          "restic-${name}-password" = {
            sopsFile = secretsFile;
          };
        }
        // (
          if targetCfg.backend == "b2" then
            {
              "restic-${name}-account-id" = {
                sopsFile = secretsFile;
              };
              "restic-${name}-account-key" = {
                sopsFile = secretsFile;
              };
            }
          else if targetCfg.backend == "s3" then
            {
              "restic-${name}-access-key-id" = {
                sopsFile = secretsFile;
              };
              "restic-${name}-secret-access-key" = {
                sopsFile = secretsFile;
              };
            }
          else
            { }
        )
      ) (lib.filterAttrs (_n: v: v.enable) cfg.targets)
    );

    # Monitoring for each target
    systemd.services =
      lib.mapAttrs' (
        name: _targetCfg:
        lib.nameValuePair "restic-backups-${name}" {
          onFailure = [ "backup-failure-notify@%n.service" ];
        }
      ) (lib.filterAttrs (_n: v: v.enable) cfg.targets)
      // {
        # Notification service for backup failures
        "backup-failure-notify@" = {
          description = "Notify on backup failure for %i";
          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${pkgs.writeShellScript "notify-backup-failure" ''
              SERVICE_NAME="$1"
              echo "⚠️  BACKUP FAILED: $SERVICE_NAME failed at $(date)"
              ${pkgs.systemd}/bin/journalctl -u "$SERVICE_NAME" -n 20 --no-pager

              # Remove old backup warnings from motd, then add new one
              ${pkgs.gnugrep}/bin/grep -v "WARNING: Backup failed" /etc/motd > /etc/motd.tmp 2>/dev/null || true
              echo "⚠️  WARNING: Backup failed on $(date) - run 'journalctl -u $SERVICE_NAME' to investigate" >> /etc/motd.tmp
              mv /etc/motd.tmp /etc/motd

              for user_session in $(${pkgs.systemd}/bin/loginctl list-sessions --no-legend | ${pkgs.gawk}/bin/awk '{print $1}'); do
                user=$(${pkgs.systemd}/bin/loginctl show-session "$user_session" -p Name --value)
                session_type=$(${pkgs.systemd}/bin/loginctl show-session "$user_session" -p Type --value)

                # Only try to notify graphical sessions (X11 or Wayland)
                if [ "$session_type" = "wayland" ] || [ "$session_type" = "x11" ]; then
                  user_id=$(id -u "$user")
                  # Use systemd-run to run in user's session context
                  ${pkgs.systemd}/bin/systemd-run --machine="$user@.host" --user --collect --wait \
                    ${pkgs.libnotify}/bin/notify-send --urgency=critical "Backup Failed" "System backup failed. Check 'journalctl -u $SERVICE_NAME'" 2>&1 || true
                fi
              done
            ''} %i";
          };
        };

        # Daily healthcheck for all targets
        restic-backup-healthcheck = {
          description = "Check if backups are running successfully";
          serviceConfig = {
            Type = "oneshot";
            ExecStart = pkgs.writeShellScript "backup-healthcheck" ''
              failed=""
              ${lib.concatStringsSep "\n" (
                lib.mapAttrsToList (name: _targetCfg: ''
                  last_success=$(${pkgs.systemd}/bin/journalctl -u restic-backups-${name}.service -g "Backup to ${name} completed successfully" --since "3 days ago" | tail -n 1)
                  if [ -z "$last_success" ]; then
                    failed="$failed ${name}"
                  fi
                '') (lib.filterAttrs (_n: v: v.enable) cfg.targets)
              )}

              if [ -n "$failed" ]; then
                message="⚠️  CRITICAL: No successful backup in 3+ days for:$failed"
                echo "$message"

                # Remove old backup warnings from motd, then add new one
                ${pkgs.gnugrep}/bin/grep -v "CRITICAL: No successful backup" /etc/motd > /etc/motd.tmp 2>/dev/null || true
                echo "$message" >> /etc/motd.tmp
                mv /etc/motd.tmp /etc/motd

                for user_session in $(${pkgs.systemd}/bin/loginctl list-sessions --no-legend | ${pkgs.gawk}/bin/awk '{print $1}'); do
                  user=$(${pkgs.systemd}/bin/loginctl show-session "$user_session" -p Name --value)
                  session_type=$(${pkgs.systemd}/bin/loginctl show-session "$user_session" -p Type --value)

                  # Only try to notify graphical sessions (X11 or Wayland)
                  if [ "$session_type" = "wayland" ] || [ "$session_type" = "x11" ]; then
                    user_id=$(id -u "$user")
                    # Use systemd-run to run in user's session context
                    ${pkgs.systemd}/bin/systemd-run --machine="$user@.host" --user --collect --wait \
                      ${pkgs.libnotify}/bin/notify-send --urgency=critical "Backup Alert" "$message" 2>&1 || true
                  fi
                done
                exit 1
              fi
            '';
          };
        };
      };

    systemd.timers.restic-backup-healthcheck = {
      description = "Daily backup health check";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "daily";
        Persistent = true;
      };
    };
  };
}
