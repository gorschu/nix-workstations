# Feature Specification: Impermanence-Backed Workstation Persistence

**Feature Branch**: `main`

**Created**: 2026-06-30

**Status**: Draft

**Input**: User description: "Integrate impermanence so the root dataset is
reset on every boot, keep `/home/<user>` persistent, declare selected user data
in a separate safe-haven area, and point restic backups at that curated
safe-haven data instead of backing up the entire home directory with a growing
exclude list."

## Clarifications

### Session 2026-06-30

- Q: What should happen when a supported host lacks required storage datasets or the root baseline snapshot? → A: Block activation for that host until required datasets and the root baseline snapshot are verified; documentation explains migration or reinstall.
- Q: Should undeclared files under `/home/<user>` disappear on reboot, or should `/home/<user>` remain persistent while declared impermanence data lives in a separate safe-haven area? → A: `/home/<user>` remains persistent; declared impermanence data lives in a separate persistent safe-haven area that backups target.
- Q: What is the canonical filesystem path for the curated safe-haven user data? → A: `/persist/home/<user>`, backed by the existing persistent `/persist` dataset.
- Q: How should declared safe-haven entries be accessed by applications and the user? → A: Store declared safe-haven data under `/persist/home/<user>` and expose it at the expected `/home/<user>/...` paths.
- Q: Must the feature explicitly inventory root-owned system state that has to survive root resets? → A: Yes; activation must require a reviewed persistent system-state inventory covering machine identity, ZFS identity/import state, SSH host keys, and secret-decryption material.
- Q: Where should Home Manager user safe-haven persistence options and declarations live? → A: Add a dedicated `modules/home/persistence/` category with `homeconfig.persistence.enable` and `homeconfig.persistence.safeHaven.enable`; persistence owns aggregation and defaults, while app-specific modules may contribute entries later.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Clean Root on Every Boot (Priority: P1)

As the workstation operator, I want each supported workstation to boot with a
clean root filesystem while declared system state survives, so accidental files,
cache buildup, and undeclared machine drift disappear automatically.

**Why this priority**: This is the foundation of the impermanence workflow. User
home persistence and backup cleanup only make sense once the system root has a
known clean baseline.

**Independent Test**: On a supported workstation or VM, create an undeclared
throwaway file under the root filesystem, reboot, and confirm the file is gone
while declared persistent system state remains available.

**Acceptance Scenarios**:

1. **Given** a workstation with impermanent root enabled, **When** the machine
   reboots, **Then** undeclared root filesystem changes from the previous boot
   are absent.
2. **Given** system state declared as persistent, **When** the machine reboots,
   **Then** that state is still present and services depending on it continue to
   work.

---

### User Story 2 - Curated User Safe-Haven Persistence (Priority: P2)

As the primary user, I want my existing `/home/<user>` contents to remain
persistent while important personal and application state can be declared in
`/persist/home/<user>` and exposed at normal `/home/<user>/...` paths, so
backup scope becomes explicit without making the rest of my home directory
ephemeral.

**Why this priority**: The main user-facing value is replacing backup exclude
maintenance with an explicit list of what matters while preserving the existing
home-directory behavior.

**Independent Test**: Add one file through the declared `/persist/home/<user>`
safe-haven path and one ordinary file elsewhere under `/home/<user>`, reboot,
and confirm both remain available while backup source review includes only the
safe-haven data by default.

**Acceptance Scenarios**:

1. **Given** a user file or directory is declared persistent, **When** the user
   logs in after a reboot, **Then** the file or directory is stored under
   `/persist/home/<user>` and available at the expected `/home/<user>/...`
   path.
2. **Given** an ordinary user file is not declared in the safe-haven scope,
   **When** the machine reboots, **Then** it remains available under the
   persistent home directory but is outside the default backup source scope.

---

### User Story 3 - Backups Target Curated Safe-Haven Data (Priority: P3)

As the workstation operator, I want backups to read from the curated
impermanence safe-haven data instead of the whole home directory, so backups
contain important data without constant exclude maintenance or unwanted
disposable files.

**Why this priority**: This completes the storage workflow by connecting
persistence decisions to backup scope while preserving the existing backup
targets and credentials.

**Independent Test**: Run a backup validation for an affected host and confirm
the selected backup paths include the curated safe-haven data and do not require
broad home-directory exclude rules for common disposable paths.

**Acceptance Scenarios**:

1. **Given** a host has backup targets enabled, **When** backup configuration is
   evaluated, **Then** the backup source includes the curated safe-haven user
   data area.
2. **Given** disposable user data is outside the curated safe-haven area,
   **When** backup scope is reviewed, **Then** that disposable data is not part
   of the default backup source.

---

### User Story 4 - Migration and Install Readiness (Priority: P4)

As the workstation operator, I want the repository to detect whether the needed
storage layout already exists and document the path when it does not, so I can
apply the feature safely to existing machines and new installs.

**Why this priority**: The current shared storage layout appears to include the
needed root and persistent datasets, but rollout still needs an explicit
operator path for hosts that were installed before the final layout.

**Independent Test**: Review each supported workstation against the required
storage layout and confirm the feature either uses existing datasets or provides
a clear reinstall or migration path before activation.

**Acceptance Scenarios**:

1. **Given** a host already has the required storage layout, **When** the
   feature is enabled, **Then** no reinstall is required.
2. **Given** a host lacks a required dataset or baseline snapshot, **When** the
   feature is planned, **Then** the operator receives an explicit migration or
   reinstall procedure before the host is switched.

### Edge Cases

- If a host has the feature disabled, current home and backup behavior remains
  unchanged.
- If required root or persistent datasets are absent, or the root baseline
  snapshot is absent, activation is blocked for that host until the storage
  layout is verified and documentation explains migration or reinstall.
- If the root reset succeeds but a declared persistent path is unavailable, the
  host must fail visibly rather than silently losing important state.
- If a required system-state path is missing from the persistence inventory,
  activation fails visibly rather than booting with regenerated identity,
  unavailable ZFS imports, inaccessible SSH, or broken secret decryption.
- Ordinary `/home/<user>` contents remain persistent even when they are not
  declared in the safe-haven scope; undeclared home data is excluded from the
  default backup source, not deleted on reboot.
- If `/persist/home/<user>` is unavailable when safe-haven persistence is
  enabled, activation fails visibly before backup scope is changed.
- If a declared safe-haven entry cannot be exposed at its expected
  `/home/<user>/...` path, activation fails visibly rather than leaving
  applications pointed at missing or unmanaged state.
- If backups are disabled on a validation host, the host can still validate root
  and home persistence without requiring backup credentials.
- If standalone Home Manager runs outside NixOS, user persistence defaults to
  disabled unless the host-level storage support exists.
- Rollback must allow the operator to return to the previous persistent-home
  backup scope without deleting curated safe-haven data.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Supported workstation hosts MUST provide an enableable
  impermanent-root mode that resets undeclared root filesystem changes on every
  boot.
- **FR-002**: The feature MUST preserve declared system state required for boot,
  users, networking, secrets, logs, package state, and enabled services.
- **FR-003**: The feature MUST include a reviewed persistent system-state
  inventory before activation. The inventory MUST cover at least machine
  identity such as `/etc/machine-id`, ZFS identity/import state such as host ID
  and import/cache state, SSH host keys, and host/user key material required to
  decrypt configured secrets.
- **FR-004**: The feature MUST verify that each supported host has the required
  root baseline snapshot and persistent storage areas before activation.
- **FR-005**: If required storage areas or the root baseline snapshot are
  missing, the feature MUST block activation for that host and document a
  migration or reinstall path instead of assuming the host can be switched
  safely.
- **FR-006**: The primary user's `/home/<user>` directory MUST remain
  persistent, and the user MUST have a separate curated safe-haven scope rooted
  at `/persist/home/<user>` for important files and application state that
  should participate in the impermanence and backup workflow.
- **FR-007**: Declared safe-haven entries MUST be stored under
  `/persist/home/<user>` and exposed at their expected `/home/<user>/...` paths
  so applications continue to use normal home-directory locations.
- **FR-008**: Disposable user data such as caches, downloads, generated indexes,
  and container or VM working data MAY remain under persistent `/home/<user>`
  but MUST remain outside the default curated backup scope unless explicitly
  declared in the safe-haven scope.
- **FR-009**: Safe-haven declarations MUST be reviewable in the repository and
  grouped clearly enough for an operator to understand why each path persists.
- **FR-010**: Backup configuration for affected hosts MUST be able to target
  `/persist/home/<user>` instead of the whole home directory.
- **FR-011**: Existing backup repositories, schedules, retention behavior, and
  secret credentials MUST remain unchanged unless the operator explicitly
  changes them.
- **FR-012**: The feature MUST preserve the repository's identity model by using
  configured user metadata rather than hardcoded personal paths in reusable
  modules.
- **FR-013**: Home Manager safe-haven persistence options and declarations MUST
  live under a dedicated top-level `homeconfig.persistence` category implemented
  in `modules/home/persistence/`, not under the CLI or GUI categories. The
  category MUST use two-level enable gates such as
  `homeconfig.persistence.enable && homeconfig.persistence.safeHaven.enable`;
  application-specific modules MAY contribute entries through this persistence
  owner later.
- **FR-014**: The feature MUST provide validation steps for the primary
  workstation targets and a VM-safe path for checking root and home persistence.
- **FR-015**: Documentation MUST explain first activation, reboot validation,
  backup-scope validation, migration or reinstall conditions, and rollback.

### Configuration Impact *(mandatory)*

- **Affected Hosts**: `hephaestus` and `apollo`; `hephaestus-vm` for validation
  where backup credentials are not required.
- **Affected Standalone Home Profiles**: `gorschu@hephaestus` only for user
  persistence declarations that also apply when embedded in NixOS.
- **Affected Module Groups**: storage-focused NixOS modules, dedicated Home
  Manager persistence modules, shared workstation storage/profile
  configuration, and backup configuration.
- **New or Changed Options**: Host-level impermanence enablement, top-level
  Home Manager persistence enablement, safe-haven subcategory enablement,
  safe-haven path declarations, and backup path selection.
- **Secrets and Recipients**: No new secret material is expected; existing
  backup and user secret recipients must remain valid.
- **Docs to Update**: Host setup, backup setup, and any module guidance affected
  by the persistence and backup workflow.

### Key Entities *(include if feature involves structured data or state)*

- **Root Persistence Baseline**: The clean root state restored on each boot, plus
  the list of system paths that intentionally survive.
- **Persistent System-State Inventory**: The reviewed set of root-owned paths
  that must survive root resets so boot, networking identity, ZFS imports, SSH
  access, secret decryption, logs, package state, and enabled services continue
  to work.
- **User Safe-Haven Scope**: The selected user files and directories under
  `/persist/home/<user>` that are declared as important personal or application
  state for impermanence and backup selection, exposed at their expected
  `/home/<user>/...` paths while the wider `/home/<user>` directory remains
  persistent. This scope is owned by the top-level Home Manager
  `homeconfig.persistence` category.
- **Backup Source Scope**: The set of persistent paths included in restic
  backups for an affected host, including `/persist/home/<user>` by default
  when safe-haven backups are enabled.
- **Storage Readiness Check**: The operator-visible decision that a host can use
  existing storage layout or requires migration before activation.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: On a validation host, an undeclared root filesystem test file is
  absent after one reboot while declared persistent system state remains
  available.
- **SC-002**: Before activation, a reviewer can identify the persisted
  system-state inventory and confirm it includes machine identity, ZFS
  identity/import state, SSH host keys, and secret-decryption material.
- **SC-003**: On a validation host, a declared safe-haven test file and an
  ordinary home-directory test file both remain available after one reboot, but
  only the safe-haven data is included in the default backup source scope.
- **SC-004**: For each affected workstation host, the selected backup source can
  be reviewed in under 5 minutes and points at curated safe-haven data rather
  than the whole home directory.
- **SC-005**: Existing backup targets continue to evaluate with the same
  repository, schedule, retention, and credential expectations after the backup
  source scope changes.
- **SC-006**: The operator documentation lets a future host setup identify
  whether migration or reinstall is required before enabling the feature.
- **SC-007**: A reviewer can identify every safe-haven user path and its purpose
  from repository configuration without inspecting live machine state.

## Assumptions

- The initial target hosts are the existing shared workstation systems:
  `hephaestus` and `apollo`.
- The VM host is used for validation where possible, with backups remaining
  disabled by design.
- The shared workstation storage layout is expected to already provide an
  ephemeral root dataset, a persistent home area, and a persistent system state
  area, but the feature must verify this before relying on it.
- The curated user safe-haven is rooted at `/persist/home/<user>` and backed by
  the existing persistent `/persist` dataset unless planning discovers a
  repository constraint that requires a more specific child dataset.
- Declared safe-haven entries are made available at their normal
  `/home/<user>/...` paths rather than requiring applications or the user to
  access `/persist/home/<user>` directly.
- Home Manager safe-haven declarations are owned by a dedicated
  `modules/home/persistence/` category using `homeconfig.persistence.*` options,
  not by `homeconfig.cli.*` or `homeconfig.gui.*`.
- The primary user is resolved through repository user metadata rather than
  hardcoded in reusable modules.
- Existing backup targets and credentials are retained; the intended change is
  backup source scope, not backup destination management.
