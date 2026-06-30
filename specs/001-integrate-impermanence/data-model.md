# Data Model: Impermanence-Backed Workstation Persistence

## Root Persistence Baseline

Represents the clean root filesystem state restored at boot.

Fields:

- `dataset`: ZFS dataset used as `/`; expected default is
  `zroot/encrypted/ephemeral/root`.
- `blankSnapshot`: snapshot name used as the reset point; expected default is
  `zroot/encrypted/ephemeral/root@blank`.
- `enabledHosts`: workstation hosts where root reset is enabled.
- `readinessRequired`: whether activation must prove the dataset and snapshot
  exist before enabling reset.
- `rollbackMode`: behavior used at boot to restore the clean baseline.

Relationships:

- Depends on Storage Readiness Check.
- Provides the clean base that Persistent System-State Inventory and User
  Safe-Haven Scope are exposed onto.

Validation rules:

- `dataset` must be mounted as `/` for enabled hosts.
- `blankSnapshot` must exist before root reset can be enabled.
- Root reset must not affect `/nix`, `/persist`, `/home`, `/var/log`,
  `/var/cache`, curated user safe-haven data, backup repositories, or other
  declared persistent datasets.

State transitions:

- `disabled` -> `ready`: required dataset and blank snapshot exist.
- `ready` -> `active`: host configuration enables root reset.
- `active` -> `rolledBack`: boot process restores root to blank baseline.
- `active` -> `disabled`: rollback of the feature stops future root resets
  without deleting persistent data.

## Persistent System-State Inventory

Represents root-owned paths and evaluated state that intentionally survive the
root reset.

Fields:

- `persistentStoragePath`: persistent system storage root, expected to be
  `/persist`.
- `files`: declared system files that must survive root reset.
- `directories`: declared system directories that must survive root reset.
- `evaluatedState`: declarative values that must remain stable without
  persisting a mutable file, such as `networking.hostId`.
- `ownerMetadata`: ownership and mode declarations for paths that need them.
- `reasons`: attrset keyed by exact live path or evaluated-state key, containing
  the human-readable purpose for each item.
- `backupPaths`: persistent backing paths from this inventory that are also
  included in restic backup scope.

Minimum entries:

- Machine identity: `/etc/machine-id`.
- SSH host identity: `/persist/etc/ssh/ssh_host_*` private and public keys,
  consumed directly by sops-nix and OpenSSH rather than by impermanence.
- ZFS identity/import state: evaluated `networking.hostId` and any file-backed
  host ID or zpool cache path introduced by implementation.
- Secret bootstrap dependencies: stable SSH host keys for sops host-recipient
  decryption; runtime `/run/secrets` outputs are regenerated and are not
  persisted.
- Host-conditional service state: service directories required by enabled
  services, such as Tailscale state when Tailscale is enabled.

Relationships:

- Mounted or linked by impermanence after Root Persistence Baseline is active.
- Gates Storage Readiness Check.
- May feed Backup Source Scope only for deliberately backed-up state.

Validation rules:

- Every persisted path must have a reason.
- Every evaluated-state key must have a reason.
- Paths required for boot, SSH, ZFS import, users, sops-nix, or early services
  must be available before their consumers start.
- Secret material must remain in the existing sops-managed flow; generated
  `/run/secrets` files must not be treated as persistent source data.
- A missing inventory entry for a required path blocks activation.
- System-state backup inclusion is opt-in through `backupPaths`; persistence for
  boot safety does not automatically make a path part of restic backups.

State transitions:

- `candidate`: path or evaluated value is identified during review.
- `classified`: candidate is marked persisted, declarative/regenerated, or
  intentionally ephemeral.
- `declared`: persisted path is listed in repository configuration.
- `materialized`: persisted path exists in persistent storage and is exposed to
  the live filesystem.
- `validated`: reboot validation proves consumers still work.
- `removed`: path is no longer declared, but persistent data is not deleted
  automatically by rollback.

## User Safe-Haven Scope

Represents selected primary-user files and directories that participate in
impermanence exposure and curated backups while the wider home directory remains
persistent.

Fields:

- `username`: resolved from user metadata.
- `homeDirectory`: expected live home path, `/home/<user>`.
- `persistentStoragePath`: storage root for curated user data,
  `/persist/home/<user>`.
- `directories`: user directories to store under the safe-haven and expose at
  expected home paths.
- `files`: user files to store under the safe-haven and expose at expected home
  paths.
- `ordinaryHomePolicy`: ordinary files under `/home/<user>` remain persistent
  but are outside the default backup source.
- `reason`: purpose for each safe-haven group.
- `contributors`: optional app-specific modules that add entries to the
  persistence-owned lists.

Relationships:

- Owned by the dedicated top-level Home Manager `homeconfig.persistence`
  category when impermanence options are available under embedded NixOS Home
  Manager.
- Depends on the NixOS impermanence module being imported and `/persist` being
  mounted.
- Feeds Backup Source Scope through `/persist/home/<user>`.

Validation rules:

- Reusable modules must not hardcode the username or home directory.
- Safe-haven declarations must not live under `homeconfig.cli.*` or
  `homeconfig.gui.*`; they use the two-level
  `homeconfig.persistence.enable && homeconfig.persistence.safeHaven.enable`
  gate.
- App-specific modules may contribute entries, but `modules/home/persistence/`
  owns aggregation and emits the final impermanence declarations.
- Safe-haven storage path is `/persist/home/<user>`, not inside the live home
  dataset.
- Declared entries must appear at their expected `/home/<user>/...` paths.
- Disposable caches, downloads, generated indexes, container stores, and VM
  working data stay out of the default curated backup scope unless explicitly
  added.
- Standalone Home Manager profiles default this integration off unless host
  support exists and the impermanence option surface is available.

State transitions:

- `disabled`: no safe-haven declarations applied.
- `declared`: repository lists user paths in the safe-haven scope.
- `materialized`: persisted user data appears at expected home paths.
- `validated`: declared safe-haven data survives reboot, ordinary home data
  also survives, and only safe-haven data is in the default backup source.

## Backup Source Scope

Represents the paths restic uses as backup input.

Fields:

- `paths`: backup source paths.
- `targets`: enabled backup destinations.
- `retention`: existing retention policy.
- `schedule`: existing timer configuration.
- `credentials`: existing sops-backed credential references.
- `excludeFiles`: remaining narrow exclude files, if any.

Relationships:

- Uses User Safe-Haven Scope as the primary home-data backup source.
- Reuses existing restic targets and secrets.
- May include selected Persistent System-State Inventory paths.

Validation rules:

- Existing target repository URLs, schedules, retention, and credentials remain
  unchanged unless explicitly modified by the operator.
- Default backup source must not be the full live home directory after the
  feature is enabled.
- Backup source review must identify `/persist/home/<user>` and any selected
  system persistence paths in under five minutes.
- Selected system persistence paths are only those listed in
  `systemState.backupPaths`.
- Rollback can restore previous backup paths without deleting safe-haven data.

State transitions:

- `legacyHomeBackup`: backup includes `/home`.
- `safeHavenBackup`: backup points at `/persist/home/<user>` plus selected
  system persistence paths.
- `validated`: evaluated backup configuration matches expected source paths.
- `rolledBack`: backup paths return to the previous source scope without
  deleting persisted data.

## Storage Readiness Check

Represents the operator-visible decision that a host is safe to enable.

Fields:

- `host`: affected host.
- `requiredDatasets`: datasets expected by the feature.
- `requiredSnapshots`: snapshots expected by the feature.
- `requiredPaths`: persistent roots expected by the feature, including
  `/persist`, `/home`, and `/persist/home/<user>`.
- `systemStateInventoryStatus`: reviewed, missing, or incomplete.
- `result`: ready, migration-required, reinstall-required, or blocked.
- `notes`: operator guidance for resolving missing storage prerequisites.

Relationships:

- Gates Root Persistence Baseline activation.
- Gates backup source changes that depend on `/persist/home/<user>`.
- Informs host setup and backup setup documentation.

Validation rules:

- Every affected physical host must have a readiness result before activation.
- A missing root baseline, persistent storage path, safe-haven root, or
  reviewed system-state inventory must block activation.
- VM validation may skip backup readiness when backups are intentionally
  disabled.

State transitions:

- `unknown`: host has not been checked.
- `ready`: host has required datasets, snapshots, paths, and inventory.
- `migrationRequired`: host can be migrated in place with documented operator
  steps.
- `reinstallRequired`: host should use the documented install path.
- `blocked`: activation must not proceed.
