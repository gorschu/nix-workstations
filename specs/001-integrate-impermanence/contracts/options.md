# Option Contract: Impermanence-Backed Workstation Persistence

This contract defines the configuration surface implementation tasks must
provide. Names may be adjusted only if the task plan updates this contract and
all references together.

## NixOS Option Surface

### `nixconfig.storage.impermanence.enable`

Type: boolean

Default: `false`

Behavior:

- Enables storage readiness checks, root reset, system-state persistence, and
  safe-haven prerequisites for supported workstation hosts.
- Does not enable restic by itself.
- Must be safe to leave disabled on a host without changing existing home or
  backup behavior.

Validation:

- If enabled, the module asserts that required datasets, snapshot names, and
  system-state inventory options are non-empty.
- If enabled and required storage is missing at runtime, activation or boot
  fails visibly before data-loss-prone behavior occurs.

### `nixconfig.storage.impermanence.rootDataset`

Type: string

Default: `zroot/encrypted/ephemeral/root`

Behavior:

- Names the ZFS dataset mounted at `/` and rolled back to a blank snapshot on
  boot.

Validation:

- Must match the shared workstation disko layout unless a host override
  documents migration or reinstall.

### `nixconfig.storage.impermanence.blankSnapshot`

Type: string

Default: `zroot/encrypted/ephemeral/root@blank`

Behavior:

- Names the clean root snapshot used as the reset point.

Validation:

- Must exist before root reset can be enabled for a host.

### `nixconfig.storage.impermanence.persistRoot`

Type: absolute path string

Default: `/persist`

Behavior:

- Root under which system persistence and safe-haven backing data live.

Validation:

- Must exist and be backed by persistent storage before activation.

### `nixconfig.storage.impermanence.userSafeHavenRoot`

Type: absolute path string

Default: `/persist/home`

Behavior:

- Parent path for per-user safe-haven backing data.
- NixOS owns only the parent storage path. The per-user
  `/persist/home/<user>` path is derived in the Home Manager persistence module
  from `config.me.username`.

Validation:

- Must not be inside the live `/home/<user>` directory.
- Must be included in backup paths when safe-haven backups are enabled.

### `nixconfig.storage.impermanence.systemState.files`

Type: list of absolute path strings

Minimum required entries:

- `/etc/machine-id`
- `/etc/ssh/ssh_host_ed25519_key`
- `/etc/ssh/ssh_host_ed25519_key.pub`
- `/etc/ssh/ssh_host_rsa_key`
- `/etc/ssh/ssh_host_rsa_key.pub`

Behavior:

- Declares root-owned files that must survive root reset.

Validation:

- Each entry must have a corresponding reason in
  `nixconfig.storage.impermanence.systemState.reasons`.
- Host-specific keys must come from the existing sops/extra-files flow; do not
  generate new host identities silently.

### `nixconfig.storage.impermanence.systemState.directories`

Type: list of absolute path strings

Initial candidate entries:

- `/var/lib/nixos`
- `/var/lib/systemd`
- `/var/lib/tailscale` when `nixconfig.networking.tailscale.enable = true`
- `/var/lib/bluetooth` when Bluetooth state needs to survive pairing

Behavior:

- Declares root-owned directories that must survive root reset.

Validation:

- Every directory must be classified as required, host-conditional, or
  intentionally excluded with a reason.

### `nixconfig.storage.impermanence.systemState.reasons`

Type: attribute set of strings

Required keys:

- Every exact path listed in `systemState.files`.
- Every exact path listed in `systemState.directories`.
- Every key listed in `systemState.evaluated`.

Behavior:

- Provides the human-reviewed reason each root-owned path or evaluated state
  item is allowed to survive root reset.
- Keys are exact live paths or evaluated-state names, for example:
  - `"/etc/machine-id"`: stable machine identity.
  - `"/etc/ssh/ssh_host_ed25519_key"`: stable SSH host identity and sops
    host-recipient decryption.
  - `"networking.hostId"`: deterministic ZFS import host ID from hostname.

Validation:

- Enabling impermanence asserts that every file, directory, and evaluated key
  has a non-empty reason.
- Reasons are audit metadata only; they do not create persistence declarations
  by themselves.

### `nixconfig.storage.impermanence.systemState.evaluated`

Type: attribute set

Minimum required entries:

- `networking.hostId`: evaluated host ID used for ZFS import identity.

Behavior:

- Records declarative values that satisfy system-state requirements without
  persisting mutable files.

Validation:

- If implementation introduces file-backed ZFS host identity such as
  `/etc/hostid`, that path must move into `systemState.files`.

### `nixconfig.storage.impermanence.systemState.backupPaths`

Type: list of absolute persistent backing paths

Default: `[ ]`

Behavior:

- Explicitly lists persisted system-state backing paths that should also be
  included in restic backups.
- System-state backup inclusion is opt-in. Persisting a path for boot safety
  does not automatically make it a backup source.

Validation:

- Every entry must correspond to a path covered by the reviewed system-state
  inventory.
- Sensitive system state such as SSH host keys or service enrollment keys must
  be intentionally listed here if it is backed up.

### `nixconfig.storage.backup.paths`

Type: existing list of path strings

Changed behavior:

- For affected hosts with backups enabled, default paths must include
  `/persist/home/<user>`.
- Additional system-state backup paths come only from
  `nixconfig.storage.impermanence.systemState.backupPaths`.
- Default paths must not include the full live `/home` directory.

Validation:

- Repository, schedule, retention, and credential behavior remain unchanged.

## Home Manager Option Surface

### `homeconfig.persistence.enable`

Type: boolean

Default:

- Embedded NixOS Home Manager: follows
  `osConfig.nixconfig.storage.impermanence.enable` when `osConfig` is available.
- Standalone Home Manager: `false`.

Behavior:

- Enables the top-level Home Manager persistence category.
- Must be paired with a subcategory gate such as
  `homeconfig.persistence.safeHaven.enable`.
- Must not emit impermanence Home Manager definitions if the upstream
  `home.persistence` option is unavailable.

Validation:

- Standalone `homeConfigurations."gorschu@hephaestus"` evaluates without host
  storage support.

### `homeconfig.persistence.safeHaven.enable`

Type: boolean

Default:

- Embedded NixOS Home Manager: follows `homeconfig.persistence.enable`.
- Standalone Home Manager: `false`.

Behavior:

- Enables curated user safe-haven declarations.
- Must be guarded by both `homeconfig.persistence.enable` and
  `homeconfig.persistence.safeHaven.enable`.

Validation:

- Safe-haven declarations are not owned by `homeconfig.cli.*` or
  `homeconfig.gui.*`.

### `homeconfig.persistence.safeHaven.path`

Type: absolute path string

Default: `/persist/home/${config.me.username}`

Behavior:

- Backing path for curated user safe-haven data.
- Declared entries are exposed at expected `/home/<user>/...` paths.

Validation:

- Must derive the username from `config.me.username`; reusable modules must not
  hardcode `gorschu`.

### `homeconfig.persistence.safeHaven.directories`

Type: list of submodule entries

Entry fields:

- `path`: relative path under the live home directory.
- `reason`: why the path belongs in the safe-haven and backup scope.

Behavior:

- Stores data under `homeconfig.persistence.safeHaven.path` and exposes it at
  `/home/<user>/<path>`.
- The dedicated persistence category owns aggregation. App-specific Home
  Manager modules may contribute entries with `lib.mkAfter` or `lib.mkMerge`,
  but the final declarations are still emitted by `modules/home/persistence/`.

Validation:

- Every entry requires a reason.
- Disposable caches, downloads, generated indexes, container storage, and VM
  working data are excluded unless explicitly justified.
- Contributions from app-specific modules must target
  `homeconfig.persistence.safeHaven.directories`; they must not create parallel
  `homeconfig.cli.*` or `homeconfig.gui.*` persistence option trees.

### `homeconfig.persistence.safeHaven.files`

Type: list of submodule entries

Entry fields:

- `path`: relative file path under the live home directory.
- `reason`: why the file belongs in the safe-haven and backup scope.

Behavior:

- Stores file data under `homeconfig.persistence.safeHaven.path` and exposes it
  at `/home/<user>/<path>`.
- The dedicated persistence category owns aggregation. App-specific Home
  Manager modules may contribute entries with `lib.mkAfter` or `lib.mkMerge`,
  but the final declarations are still emitted by `modules/home/persistence/`.

Validation:

- Every entry requires a reason.
- File parents must be materialized before use.
- Contributions from app-specific modules must target
  `homeconfig.persistence.safeHaven.files`; they must not create parallel
  `homeconfig.cli.*` or `homeconfig.gui.*` persistence option trees.
