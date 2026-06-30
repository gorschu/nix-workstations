# Implementation Plan: Impermanence-Backed Workstation Persistence

**Branch**: `main` | **Date**: 2026-06-30 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/001-integrate-impermanence/spec.md`

## Summary

Add an explicit impermanence workflow for the shared workstation hosts
`hephaestus` and `apollo`, with `hephaestus-vm` as the first runtime validation
target. The implementation will add `nix-community/impermanence` as a flake
input, import its NixOS module through shared workstation wiring, reset the
existing ZFS ephemeral root dataset to its blank baseline on boot, and declare
all root-owned system state that must survive that reset.

The user's existing `/home/<user>` dataset remains persistent. Curated
safe-haven user data is rooted at `/persist/home/<user>`, exposed back at normal
`/home/<user>/...` paths, and becomes the default restic home-data source
instead of backing up the full live home directory.

## Technical Context

**Nixpkgs / Flake Inputs**: Current repo uses `nixos-unstable`,
`home-manager`, `disko`, `sops-nix`, `flake-parts`, and restic via NixOS
modules. Add `impermanence.url = "github:nix-community/impermanence"` and make
its `nixpkgs` input follow this repo's `nixpkgs`. Import
`inputs.impermanence.nixosModules.impermanence` for workstation NixOS systems.
Do not manually import the deprecated standalone Home Manager impermanence
module output; when NixOS impermanence and NixOS Home Manager integration are
both present, upstream impermanence provides Home Manager persistence support.

**Affected NixOS Hosts**: `hephaestus`, `apollo`, and `hephaestus-vm` through
`configurations/nixos/_shared/workstation-profile.nix`; `hephaestus-vm` keeps
backups and Tailscale disabled where the host config already forces them off.

**Affected Home Profiles**: Embedded Home Manager user `gorschu` on the
workstation hosts. Standalone `homeConfigurations."gorschu@hephaestus"` must
continue to evaluate with safe-haven persistence disabled unless the
impermanence Home Manager option is available under a NixOS host.

**Module Areas**: `flake.nix`,
`configurations/nixos/_shared/workstation-profile.nix`,
`configurations/nixos/_shared/workstation-disko.nix`,
`modules/nixos/storage/`, `modules/nixos/storage/restic-backup.nix`,
`modules/home/default.nix`, `modules/home/persistence/`, `docs/`.

**Options / Enable Gates**: Add `nixconfig.storage.impermanence.enable` with
root-reset, readiness, persistent storage root, and reviewed system-state
inventory options under the storage owner. Add a dedicated top-level Home
Manager persistence category with `homeconfig.persistence.enable` and
`homeconfig.persistence.safeHaven.enable`, guarded by both enable layers and the
presence of impermanence Home Manager options when standalone profiles are
evaluated.
Backup source selection remains under `nixconfig.storage.backup`.

**Secrets / State**: No new secret material is expected. The system-state
inventory must cover at least `/etc/machine-id`, SSH host keys under
`/etc/ssh`, ZFS identity/import state, and secret-decryption dependencies. In
this repo `networking.hostId` is currently derived deterministically from the
host name, so the inventory must validate that evaluated value and only persist
a file such as `/etc/hostid` if implementation introduces one. The user age key
is provisioned through sops-nix into `/run/secrets`; the stable host SSH key is
the critical persisted bootstrap material for decrypting it.

**Operational Workflows**: Prefer `just lint`, narrow `nix build` targets for
`hephaestus-vm`, `hephaestus`, `apollo`, and the standalone Home Manager
activation package. Use `just install-vm HOST=hephaestus-vm` or the existing VM
recipes for reboot validation, and `just deploy-local` only after VM and build
validation pass. Secret key staging continues through `just decrypt-keys` and
`just install`.

**Testing / Validation**: Narrow builds:
`nix build .#nixosConfigurations.hephaestus-vm.config.system.build.toplevel`,
`nix build .#nixosConfigurations.hephaestus.config.system.build.toplevel`,
`nix build .#nixosConfigurations.apollo.config.system.build.toplevel`, and
`nix build .#homeConfigurations."gorschu@hephaestus".activationPackage`.
Runtime validation uses a VM or controlled host reboot to prove root reset,
system-state persistence, persistent `/home/<user>`, safe-haven exposure, and
backup source narrowing.

**Constraints**: Existing disko layout already defines
`zroot/encrypted/ephemeral/root`, `/persist`, `/home`, `/nix`, `/var/log`,
`/var/cache`, container datasets, and a `root@blank` snapshot hook. Activation
must fail if a host lacks required datasets, the blank root snapshot, a reviewed
system-state inventory, `/persist/home/<user>`, or a declared safe-haven entry
that cannot be exposed at the expected home path. Rollback must not delete
curated safe-haven data or persistent home data.

**Root Rollback Design**: Root reset is initrd-stage work owned by
`modules/nixos/storage/impermanence.nix`, not an activation script or late
systemd service. The rollback hook or initrd unit must run after the encrypted
ZFS pool is available and before the root filesystem is used as the live system
root. It must execute the configured rollback from
`nixconfig.storage.impermanence.blankSnapshot`, fail visibly if the dataset or
snapshot is missing, and leave `/persist`, `/home`, `/nix`, `/var/log`, and
`/var/cache` untouched.

**Scale / Scope**: One new flake input, one NixOS storage module, one top-level
Home Manager persistence category, shared workstation wiring, backup path
defaults, option contracts, and documentation updates for two physical hosts
plus one VM validation host.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **Explicit Flake Composition**: PASS. The plan adds one flake input and
  imports a shared workstation NixOS module; no host or standalone Home Manager
  profile registration changes are required.
- **Enable Gates Match Ownership**: PASS. NixOS storage behavior is owned by
  `nixconfig.storage.impermanence.*`. Home Manager safe-haven declarations are
  owned by a dedicated top-level `homeconfig.persistence` category and guarded
  by `homeconfig.persistence.enable && homeconfig.persistence.safeHaven.enable`,
  with standalone evaluation guarded when impermanence options are absent.
- **Stack Boundaries Stay Consistent**: PASS. The feature is storage and user
  state, not a desktop stack. NixOS owns root reset, mounts, readiness, and
  system persistence; Home Manager owns user path declarations.
- **Identity and Secrets Are Indirect**: PASS. User paths are derived from
  `config.me.*` / Home Manager metadata; host secret recipients remain in the
  existing sops-nix flow; SSH host keys are explicitly treated as persisted
  system bootstrap state.
- **Validated Workflow Over Raw Commands**: PASS. The plan names narrow build
  targets, `just lint`, and VM or host reboot validation before deploy.

## Project Structure

### Documentation (this feature)

```text
specs/001-integrate-impermanence/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── options.md
└── checklists/
    └── requirements.md
```

### Repository Layout

```text
flake.nix
configurations/
└── nixos/
    └── _shared/
        ├── workstation-disko.nix
        └── workstation-profile.nix
modules/
├── nixos/
│   └── storage/
│       ├── impermanence.nix
│       ├── restic-backup.nix
│       └── restic-excludes.txt
└── home/
    ├── default.nix
    └── persistence/
        ├── default.nix
        ├── options.nix
        └── safe-haven.nix
docs/
├── new-host-setup.md
└── restic-backup-setup.md
```

**Structure Decision**: Root reset, dataset readiness, system-state inventory,
and backup source defaults belong in NixOS storage modules because they affect
boot, filesystems, system services, and restic. User safe-haven path
declarations belong in a dedicated top-level Home Manager persistence category
because they are neither CLI nor GUI concerns and must use `config.me.*`
identity metadata. Disk layout remains in shared disko configuration because
disko owns dataset creation.

## Complexity Tracking

No constitution violations require justification.

## Phase 0 Research Summary

See [research.md](./research.md). All planning unknowns are resolved:

- Current impermanence flake/module integration.
- Root reset ownership between ZFS/disko and impermanence.
- Persistent system-state inventory and readiness blocking behavior.
- Persistent `/home/<user>` plus `/persist/home/<user>` safe-haven split.
- Backup source narrowing and rollback validation.

## Phase 1 Design Summary

See [data-model.md](./data-model.md), [contracts/options.md](./contracts/options.md),
and [quickstart.md](./quickstart.md). The contract artifact documents the new
NixOS and Home Manager option surface because these module options are the
configuration interface that implementation tasks must satisfy.

Agent context update is handled after artifact generation. This checkout has no
`.specify/scripts/bash/update-agent-context.sh`; the installed optional
`agent-context` extension is reported under post-execution hooks.

## Task Generation Guidance

Use this section when generating `tasks.md`. Each task should cite the relevant
artifact section in its description so implementers can find the design detail
without rediscovering it.

### Phase 1: Setup

- Verify current module auto-import patterns in `modules/nixos/storage/default.nix`
  and the new top-level Home Manager category wiring needed in
  `modules/home/default.nix`. Reference: [plan.md](./plan.md) "Repository
  Layout" and [contracts/options.md](./contracts/options.md) "Home Manager
  Option Surface".
- Inspect existing storage and backup defaults in
  `configurations/nixos/_shared/workstation-disko.nix`,
  `modules/nixos/storage/zfs.nix`, and
  `modules/nixos/storage/restic-backup.nix`. Reference:
  [data-model.md](./data-model.md) "Root Persistence Baseline" and "Backup
  Source Scope".
- Confirm validation commands from [quickstart.md](./quickstart.md) "Static
  Checks" before implementation starts.

### Phase 2: Foundational

- Add `nix-community/impermanence` to `flake.nix` and import its NixOS module
  through shared workstation wiring. Reference: [research.md](./research.md)
  "Use `nix-community/impermanence` as a flake input" and "Import NixOS
  impermanence only".
- Create `modules/nixos/storage/impermanence.nix` with
  `nixconfig.storage.impermanence.*` options, assertions, readiness checks,
  system-state inventory declarations, and root rollback configuration.
  Reference: [contracts/options.md](./contracts/options.md) "NixOS Option
  Surface", [research.md](./research.md) "Root rollback is an initrd-stage
  operation", and [data-model.md](./data-model.md) "Persistent System-State
  Inventory".
- Create `modules/home/persistence/{default.nix,options.nix,safe-haven.nix}`
  and import it from `modules/home/default.nix`. Reference:
  [contracts/options.md](./contracts/options.md) "Home Manager Option Surface"
  and [data-model.md](./data-model.md) "User Safe-Haven Scope".
- Define the app-contribution pattern for safe-haven entries: app modules may
  append to `homeconfig.persistence.safeHaven.files` and
  `homeconfig.persistence.safeHaven.directories`, but
  `modules/home/persistence/` owns final impermanence declarations. Reference:
  [contracts/options.md](./contracts/options.md)
  "`homeconfig.persistence.safeHaven.directories`" and
  "`homeconfig.persistence.safeHaven.files`".

### Core Implementation: US1 Clean Root and System State

- Implement initrd-stage ZFS rollback for
  `zroot/encrypted/ephemeral/root@blank`. Reference:
  [research.md](./research.md) "Root rollback is an initrd-stage operation" and
  [quickstart.md](./quickstart.md) "VM Reboot Validation".
- Implement storage readiness checks for `zroot/encrypted/ephemeral/root`,
  `zroot/encrypted/ephemeral/root@blank`, `/persist`, and `/home`. Reference:
  [data-model.md](./data-model.md) "Storage Readiness Check" and
  [quickstart.md](./quickstart.md) "Storage Readiness Review".
- Implement the reviewed system-state inventory with `files`, `directories`,
  `evaluated`, `reasons`, and `backupPaths`. Reference:
  [contracts/options.md](./contracts/options.md)
  "`nixconfig.storage.impermanence.systemState.reasons`" and
  [quickstart.md](./quickstart.md) "System-State Inventory Review".
- Validate that `/etc/machine-id`, `/etc/ssh/ssh_host_*`,
  `networking.hostId`, sops bootstrap behavior, and any enabled service state
  remain stable after reboot. Reference: [spec.md](./spec.md) FR-003 and
  SC-002.

### Core Implementation: US2 User Safe-Haven

- Implement `homeconfig.persistence.enable` and
  `homeconfig.persistence.safeHaven.enable` defaults: embedded NixOS follows
  `osConfig.nixconfig.storage.impermanence.enable`; standalone Home Manager
  defaults to disabled. Reference: [contracts/options.md](./contracts/options.md)
  "`homeconfig.persistence.enable`".
- Materialize `/persist/home/<user>` from `config.me.username` and expose
  declared entries at normal `/home/<user>/...` paths. Reference:
  [spec.md](./spec.md) FR-006 and FR-007, plus
  [data-model.md](./data-model.md) "User Safe-Haven Scope".
- Preserve ordinary `/home/<user>` behavior: ordinary files remain persistent
  but are outside default backup scope. Reference: [spec.md](./spec.md)
  Edge Cases and [quickstart.md](./quickstart.md) "VM Reboot Validation".

### Core Implementation: US3 Backup Source Scope

- Change affected-host restic paths away from the full live `/home` directory
  and toward `/persist/home/<user>`. Reference:
  [contracts/options.md](./contracts/options.md)
  "`nixconfig.storage.backup.paths`" and [quickstart.md](./quickstart.md)
  "Backup Scope Validation".
- Include only explicitly selected system-state backup paths from
  `nixconfig.storage.impermanence.systemState.backupPaths`. Reference:
  [contracts/options.md](./contracts/options.md)
  "`nixconfig.storage.impermanence.systemState.backupPaths`".
- Preserve restic repository URLs, schedules, retention, and credential
  references. Reference: [spec.md](./spec.md) FR-011 and SC-005.

### Core Implementation: US4 Migration and Install Readiness

- Update `docs/new-host-setup.md` with dataset, snapshot, system-state
  inventory, and `/persist/home/<user>` readiness checks. Reference:
  [quickstart.md](./quickstart.md) "Storage Readiness Review" and
  "System-State Inventory Review".
- Update `docs/restic-backup-setup.md` with safe-haven backup source behavior
  and rollback expectations. Reference: [quickstart.md](./quickstart.md)
  "Backup Scope Validation" and "Rollback Validation".
- Document what blocks activation versus what requires migration or reinstall.
  Reference: [spec.md](./spec.md) FR-004, FR-005, and FR-015.

### Refinement and Validation

- Run the narrow builds listed in [quickstart.md](./quickstart.md) "Static
  Checks".
- Run VM reboot validation before physical host deployment. Reference:
  [quickstart.md](./quickstart.md) "VM Reboot Validation".
- Run physical host validation only after VM validation passes. Reference:
  [quickstart.md](./quickstart.md) "Physical Host Runtime Validation".
- Confirm no unrelated host or standalone Home Manager profile registration
  changed in `flake.nix`. Reference: Constitution principle "Explicit Flake
  Composition".

## Post-Design Constitution Check

- **Explicit Flake Composition**: PASS. Design keeps host/profile registration
  unchanged, relies on existing auto-imported module groups, and keeps imports
  at module top level.
- **Enable Gates Match Ownership**: PASS. NixOS and Home Manager enable gates
  are explicit. The Home Manager category set is extended with
  `homeconfig.persistence`, which follows the same two-level category and
  subcategory gate pattern as existing Home Manager groups.
- **Stack Boundaries Stay Consistent**: PASS. No desktop-stack ownership
  changes.
- **Identity and Secrets Are Indirect**: PASS. Design requires user metadata,
  stable SSH host keys for sops bootstrap, and preservation of existing sops
  recipients without new plaintext secrets.
- **Validated Workflow Over Raw Commands**: PASS. Quickstart defines narrow
  evaluation, build, VM reboot, host reboot, backup-scope, and rollback checks.
