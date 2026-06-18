# Restic Backup Setup Guide

This guide explains how to set up automated restic backups with multiple targets (B2, S3-compatible, or local).

## Per-Host Setup

Each host gets its own backup buckets/repositories for isolation and to avoid lock contention. The module supports multiple backup targets simultaneously for redundancy.

### 1. Create Backup Targets

Choose one or more backup targets. Each target gets its own repository and credentials.

#### Backblaze B2

**Recommended: Shared Bucket Approach**

1. Log into Backblaze B2
2. Create a single bucket for all your workstations (e.g., `gorschu-backup-workstations`)
3. Make it private
4. Enable Object Lock if desired (optional)
5. Create an Application Key restricted to this bucket
6. Save the **keyID** (account ID) and **applicationKey**

Each host will use a separate repository directory within this bucket (e.g., `b2:gorschu-backup-workstations:hephaestus`). This means:
- One bucket for all workstations
- One set of credentials shared across all workstations
- Separate restic repositories per host (isolated, no lock contention)
- Much simpler credential management

**Alternative: Per-Host Buckets**

If you prefer complete isolation, create separate buckets per host (`<hostname>-backup`) with separate application keys.

#### S3-Compatible Storage (AWS S3, Scaleway, etc.)

Works with any S3-compatible object storage provider:

**AWS S3:**
1. Create an S3 bucket
2. Generate IAM credentials with read/write access
3. Endpoint is `s3.amazonaws.com` (or regional endpoint)

**Scaleway Object Storage:**
1. Log into Scaleway console
2. Create an Object Storage bucket
3. Generate API credentials (access key + secret key)
4. Note the region endpoint (e.g., `s3.nl-ams.scw.cloud`)

**Other S3-compatible providers** (Wasabi, MinIO, DigitalOcean Spaces, etc.):
1. Create bucket/space in your provider
2. Generate API credentials
3. Note the S3 endpoint URL

#### Local Storage

1. Create a directory for backups (e.g., `/mnt/backup`)
2. Ensure proper permissions
3. Consider mounting external USB drive or NAS

### 2. Generate Restic Passwords

Generate a strong random password for each target's restic repository:

```bash
openssl rand -base64 32
```

**Important**: Use different passwords for each target for maximum isolation.

### 3. Configure Secrets

Create the secrets file for the host:

```bash
# Create directory if it doesn't exist
mkdir -p secrets/hosts/hephaestus

# Copy the example
cp secrets/hosts/restic.yaml.example secrets/hosts/hephaestus/restic.yaml

# Edit and add your credentials (only add sections for targets you're using)
nano secrets/hosts/hephaestus/restic.yaml

# Encrypt with sops
sops -e -i secrets/hosts/hephaestus/restic.yaml
```

The secrets file should contain credentials for each target you plan to use. See `secrets/hosts/restic.yaml.example` for the complete format.

### 4. Update .sops.yaml

If your host already has a rule in `.sops.yaml` covering `secrets/hosts/<hostname>/*.yaml` (see `docs/new-host-setup.md`), no additional rule is needed — the restic secrets file will be encrypted for both the admin key and the host key automatically.

If you are adding restic secrets to an already-registered host and are unsure whether the rule exists, check `.sops.yaml` for a line like:

```yaml
- path_regex: secrets/hosts/hephaestus/[^/]+\.(yaml|json|env|ini)$
```

### 5. Enable Backups in Host Config

In your host configuration (e.g., `configurations/nixos/hephaestus/configuration.nix`):

#### Single Target (B2 with shared bucket)

```nix
{
  nixconfig.storage.backup = {
    enable = true;
    # bucketName defaults to "gorschu-backup-workstations"
    targets = {
      b2 = {
        repository = "b2:${config.nixconfig.storage.backup.bucketName}:${config.networking.hostName}";
        backend = "b2";
      };
    };
  };
}
```

#### Override Bucket Name (e.g., for servers)

```nix
{
  nixconfig.storage.backup = {
    enable = true;
    bucketName = "gorschu-backup-servers";  # Different bucket for servers
    targets = {
      b2 = {
        repository = "b2:${config.nixconfig.storage.backup.bucketName}:${config.networking.hostName}";
        backend = "b2";
      };
    };
  };
}
```

#### Multiple Targets (B2 + Scaleway for redundancy)

```nix
{
  nixconfig.storage.backup = {
    enable = true;
    targets = {
      b2 = {
        repository = "b2:${config.nixconfig.storage.backup.bucketName}:${config.networking.hostName}";
        backend = "b2";
      };
      scaleway = {
        repository = "s3:s3.nl-ams.scw.cloud/${config.nixconfig.storage.backup.bucketName}/backup-${config.networking.hostName}";
        backend = "s3";  # All S3-compatible providers use backend = "s3"
      };
    };
  };
}
```

#### Advanced: Per-Target Configuration

```nix
{
  nixconfig.storage.backup = {
    enable = true;

    # Global defaults
    paths = [
      "/home"
      "/etc"
      "/root"
    ];

    exclude = [
      "/home/*/.cache"
      "/home/*/Downloads"
    ];

    # Default schedule: every 6 hours
    defaultTimerConfig = {
      OnCalendar = "*-*-* 00/6:00:00";
      RandomizedDelaySec = "30m";
      Persistent = true;
    };

    targets = {
      b2 = {
        repository = "b2:${config.networking.hostName}-backup";
        backend = "b2";
        # Inherits defaults
      };

      local = {
        repository = "/mnt/backup/${config.networking.hostName}";
        backend = "local";
        # Override: backup more frequently to local disk
        timerConfig = {
          OnCalendar = "hourly";
          Persistent = true;
        };
        # Override: keep more local snapshots
        retention = {
          keep-hourly = 48;
          keep-daily = 30;
        };
      };
    };
  };
}
```

### 6. Initialize Repositories (First Time Only)

After deploying, initialize each restic repository. You'll need to set the environment variables manually for the init command.

#### B2 Target

```bash
# On the host
export B2_ACCOUNT_ID="your-account-id"
export B2_ACCOUNT_KEY="your-account-key"
# For shared bucket approach:
sudo -E restic -r b2:gorschu-backup-workstations:<hostname> init
# For per-host bucket approach:
# sudo -E restic -r b2:<hostname>-backup init
```

#### S3-Compatible Target (Scaleway, AWS S3, etc.)

```bash
# On the host
export AWS_ACCESS_KEY_ID="your-access-key-id"
export AWS_SECRET_ACCESS_KEY="your-secret-access-key"
# For Scaleway:
sudo -E restic -r s3:s3.nl-ams.scw.cloud/<hostname>-backup init
# For AWS S3:
sudo -E restic -r s3:s3.amazonaws.com/<bucket-name> init
```

#### Local Target

```bash
# On the host
sudo restic -r /mnt/backup/<hostname> init
```

You'll be prompted for the restic password for each repository (use the passwords from your secrets file).

### 7. Verify Backups

Check the backup service status for each target:

```bash
# Check timer for b2 target
systemctl status restic-backups-b2.timer

# Check last backup for b2 target
systemctl status restic-backups-b2.service

# Manually trigger a backup for b2 target
sudo systemctl start restic-backups-b2.service

# View backup logs for b2 target
journalctl -u restic-backups-b2.service

# For other targets, replace 'b2' with the target name (e.g., 'scaleway', 'local')
systemctl list-timers 'restic-backups-*'
```

## Features

- **Multiple backup targets**: Support for B2, S3-compatible (AWS S3, Scaleway, Wasabi, etc.), and local storage simultaneously
- **Independent target configuration**: Each target can have its own schedule and retention policy
- **6-hour backup schedule** (default): With randomized delay to spread load
- **Default retention policy** (configurable per-target):
  - Keep 16 hourly backups (4 days at 6-hour intervals)
  - Keep 14 daily backups (2 weeks)
  - Keep 8 weekly backups (2 months)
  - Keep 12 monthly backups (1 year)
  - Keep 3 yearly backups (3 years)
- **Automatic pruning**: Old snapshots are removed according to retention policy
- **Failure monitoring**: Desktop notifications + MOTD warnings on backup failures
- **Health checks**: Daily verification that backups completed successfully in last 3 days
- **Persistent timers**: Catch up missed backups after laptop sleep/shutdown
- **Secure credentials**: All keys and passwords encrypted with SOPS

## Restoring Files

You can restore from any configured backup target. The commands are the same, just change the repository URL and set the appropriate environment variables.

### From B2

```bash
# Set credentials
export B2_ACCOUNT_ID="your-account-id"
export B2_ACCOUNT_KEY="your-account-key"

# List snapshots
sudo -E restic -r b2:gorschu-backup-workstations:<hostname> snapshots

# List files in a snapshot
sudo -E restic -r b2:gorschu-backup-workstations:<hostname> ls <snapshot-id>

# Restore a specific file
sudo -E restic -r b2:gorschu-backup-workstations:<hostname> restore <snapshot-id> --target /tmp/restore --include /path/to/file

# Restore entire snapshot
sudo -E restic -r b2:gorschu-backup-workstations:<hostname> restore latest --target /tmp/restore
```

### From S3-Compatible (Scaleway, AWS, etc.)

```bash
# Set credentials
export AWS_ACCESS_KEY_ID="your-access-key-id"
export AWS_SECRET_ACCESS_KEY="your-secret-access-key"

# For Scaleway:
sudo -E restic -r s3:s3.nl-ams.scw.cloud/<hostname>-backup snapshots
sudo -E restic -r s3:s3.nl-ams.scw.cloud/<hostname>-backup restore latest --target /tmp/restore

# For AWS S3:
sudo -E restic -r s3:s3.amazonaws.com/<bucket-name> snapshots
sudo -E restic -r s3:s3.amazonaws.com/<bucket-name> restore latest --target /tmp/restore
```

### From Local

```bash
# No credentials needed for local
sudo restic -r /mnt/backup/<hostname> snapshots
sudo restic -r /mnt/backup/<hostname> restore latest --target /tmp/restore
```

## Monitoring

The backup runs as a systemd timer for each target. You can monitor them with:

```bash
# Check all backup timers
systemctl list-timers 'restic-backups-*'

# Check specific target timer
systemctl status restic-backups-b2.timer

# View recent logs for specific target
journalctl -u restic-backups-b2.service -n 50

# View logs for all backup services
journalctl -u 'restic-backups-*' --since today

# Check health monitoring
systemctl status restic-backup-healthcheck.service
journalctl -u restic-backup-healthcheck.service
```

## Troubleshooting

### Stale Locks

If you see "repository is already locked" errors, you can manually unlock:

```bash
# For B2
export B2_ACCOUNT_ID="..." B2_ACCOUNT_KEY="..."
sudo -E restic -r b2:gorschu-backup-workstations:<hostname> unlock

# For S3-compatible (set the appropriate endpoint)
export AWS_ACCESS_KEY_ID="..." AWS_SECRET_ACCESS_KEY="..."
sudo -E restic -r s3:s3.nl-ams.scw.cloud/<hostname>-backup unlock  # Scaleway
sudo -E restic -r s3:s3.amazonaws.com/<bucket-name> unlock         # AWS S3

# For local
sudo restic -r /mnt/backup/<hostname> unlock
```

**Note**: Restic automatically refreshes locks every 5 minutes for active backups. The unlock command only removes locks older than 30 minutes, so it's safe to run even during an active backup.

### Check Repository Integrity

```bash
# For B2 (set credentials first)
export B2_ACCOUNT_ID="..." B2_ACCOUNT_KEY="..."
sudo -E restic -r b2:gorschu-backup-workstations:<hostname> check

# For S3-compatible
export AWS_ACCESS_KEY_ID="..." AWS_SECRET_ACCESS_KEY="..."
sudo -E restic -r s3:s3.nl-ams.scw.cloud/<hostname>-backup check  # Scaleway
sudo -E restic -r s3:s3.amazonaws.com/<bucket-name> check         # AWS S3

# For local
sudo restic -r /mnt/backup/<hostname> check
```

### View Repository Stats

```bash
# For B2
export B2_ACCOUNT_ID="..." B2_ACCOUNT_KEY="..."
sudo -E restic -r b2:gorschu-backup-workstations:<hostname> stats

# For S3-compatible: same pattern, adjust repository URL
export AWS_ACCESS_KEY_ID="..." AWS_SECRET_ACCESS_KEY="..."
sudo -E restic -r s3:s3.nl-ams.scw.cloud/<hostname>-backup stats
```

### Backup Not Running

If backups aren't running:

1. Check the timer is active:
   ```bash
   systemctl list-timers 'restic-backups-*'
   ```

2. Check service status:
   ```bash
   systemctl status restic-backups-b2.service
   ```

3. Check for errors in logs:
   ```bash
   journalctl -u restic-backups-b2.service -n 100
   ```

4. Verify secrets are correctly configured:
   ```bash
   # Check if secret files exist
   ls -la /run/secrets/restic-*

   # Check if template was generated
   cat /run/secrets-rendered/restic-env-b2
   ```

### Desktop Notifications Not Working

If you're not receiving failure notifications:

1. Check the notification service:
   ```bash
   journalctl -u 'backup-failure-notify@*'
   ```

2. Verify you have an active graphical session:
   ```bash
   loginctl list-sessions
   ```

3. Test manual notification:
   ```bash
   notify-send "Test" "This is a test notification"
   ```

## Multi-Target Strategy

When using multiple backup targets, consider:

- **Primary + Secondary**: B2 as primary (6-hour schedule), Scaleway as secondary (daily schedule)
- **Cloud + Local**: B2 for offsite, local USB/NAS for quick restores
- **Different retention**: Keep more snapshots locally, fewer in cloud for cost optimization
- **Staggered schedules**: Offset backup times to reduce system load

Example configuration:

```nix
{
  nixconfig.storage.backup = {
    enable = true;

    defaultTimerConfig = {
      OnCalendar = "*-*-* 00/6:00:00";  # Every 6 hours
      RandomizedDelaySec = "30m";
      Persistent = true;
    };

    targets = {
      # Primary cloud backup
      b2 = {
        repository = "b2:${config.networking.hostName}-backup";
        backend = "b2";
      };

      # Secondary cloud backup (less frequent)
      scaleway = {
        repository = "s3:s3.nl-ams.scw.cloud/${config.networking.hostName}-backup";
        backend = "s3";  # All S3-compatible providers use "s3"
        timerConfig = {
          OnCalendar = "daily";  # Once per day
          RandomizedDelaySec = "2h";
          Persistent = true;
        };
      };

      # Local backup (frequent, more retention)
      local = {
        repository = "/mnt/backup/${config.networking.hostName}";
        backend = "local";
        timerConfig.OnCalendar = "hourly";
        retention = {
          keep-hourly = 48;   # 2 days
          keep-daily = 30;    # 1 month
          keep-weekly = 12;   # 3 months
          keep-monthly = 24;  # 2 years
        };
      };
    };
  };
}
```
