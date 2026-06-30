# Tasks: Impermanence-Backed Workstation Persistence

**Input**: Design documents from `/specs/001-integrate-impermanence/`

**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`,
`contracts/options.md`, `quickstart.md`

**Tests**: Include validation tasks for every changed host/profile/module.
Runtime reboot validation is required because this feature changes boot-time ZFS
rollback, persistent state exposure, Home Manager persistence, and restic backup
source selection.

**Organization**: Tasks are grouped by user story so each configuration slice
can be implemented and validated independently.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel because it touches different files and has no
  dependency on another incomplete task
- **[Story]**: Which user story this task belongs to: `[US1]`, `[US2]`,
  `[US3]`, or `[US4]`
- Every task includes exact file paths and points to the relevant design
  artifact section

## Phase 1: Setup (Shared Context)

**Purpose**: Confirm repository wiring, existing storage layout, and validation
entrypoints before implementation.

- [X] T001 Review storage module auto-import behavior in `modules/nixos/storage/default.nix` against `specs/001-integrate-impermanence/plan.md` "Repository Layout"
- [X] T002 [P] Review Home Manager root imports in `modules/home/default.nix` for the new `./persistence` category against `specs/001-integrate-impermanence/contracts/options.md` "Home Manager Option Surface"
- [X] T003 [P] Review existing ZFS datasets and `root@blank` snapshot creation in `configurations/nixos/_shared/workstation-disko.nix` against `specs/001-integrate-impermanence/data-model.md` "Root Persistence Baseline"
- [X] T004 [P] Review existing backup defaults in `modules/nixos/storage/restic-backup.nix` and `modules/nixos/storage/restic-excludes.txt` against `specs/001-integrate-impermanence/data-model.md` "Backup Source Scope"
- [X] T005 [P] Review host backup and Tailscale toggles in `configurations/nixos/hephaestus/configuration.nix`, `configurations/nixos/apollo/configuration.nix`, and `configurations/nixos/hephaestus-vm/default.nix` against `specs/001-integrate-impermanence/spec.md` "Configuration Impact"
- [X] T006 [P] Confirm validation commands in `specs/001-integrate-impermanence/quickstart.md` and available recipes in `justfile`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Add shared flake/module scaffolding that all user stories depend
on.

**CRITICAL**: No user story work can begin until this phase is complete.

- [X] T007 Add `impermanence.url = "github:nix-community/impermanence"` with `inputs.nixpkgs.follows = "nixpkgs"` in `flake.nix` per `specs/001-integrate-impermanence/research.md` "Use `nix-community/impermanence` as a flake input"
- [X] T008 Import `inputs.impermanence.nixosModules.impermanence` through shared workstation wiring in `configurations/nixos/_shared/workstation-profile.nix` per `specs/001-integrate-impermanence/research.md` "Import NixOS impermanence only"
- [X] T009 Create the NixOS storage module scaffold in `modules/nixos/storage/impermanence.nix` with top-level `imports` absent from any `config` block per `specs/001-integrate-impermanence/contracts/options.md` "NixOS Option Surface"
- [X] T010 Create the Home Manager persistence category import scaffold in `modules/home/persistence/default.nix` per `specs/001-integrate-impermanence/plan.md` "Repository Layout"
- [X] T011 [P] Create Home Manager persistence options scaffold in `modules/home/persistence/options.nix` with `homeconfig.persistence.enable` and `homeconfig.persistence.safeHaven.enable` per `specs/001-integrate-impermanence/contracts/options.md` "Home Manager Option Surface"
- [X] T012 [P] Create Home Manager safe-haven implementation scaffold in `modules/home/persistence/safe-haven.nix` per `specs/001-integrate-impermanence/data-model.md` "User Safe-Haven Scope"
- [X] T013 Import `./persistence` from `modules/home/default.nix` alongside `./cli` and `./gui` per `specs/001-integrate-impermanence/spec.md` FR-013
- [X] T014 Verify `flake.nix` does not add unrelated NixOS host or standalone Home Manager profile registrations per `.specify/memory/constitution.md` "Explicit Flake Composition"

**Checkpoint**: Flake input, NixOS module scaffold, and Home Manager persistence
category scaffold are in place.

---

## Phase 3: User Story 1 - Clean Root on Every Boot (Priority: P1)

**Goal**: Supported workstation hosts boot from a clean root dataset while
reviewed system state survives root reset.

**Independent Test**: Build `hephaestus-vm`, review the system-state inventory,
then reboot a validation host and confirm `/root-should-disappear` is gone while
declared system state remains available.

### Implementation for User Story 1

- [X] T015 [US1] Define `nixconfig.storage.impermanence.enable`, `rootDataset`, `blankSnapshot`, `persistRoot`, and `userSafeHavenRoot` options in `modules/nixos/storage/impermanence.nix` per `specs/001-integrate-impermanence/contracts/options.md` "NixOS Option Surface"
- [X] T016 [US1] Define `nixconfig.storage.impermanence.systemState.files`, `directories`, `evaluated`, `reasons`, and `backupPaths` options in `modules/nixos/storage/impermanence.nix` per `specs/001-integrate-impermanence/contracts/options.md` "`nixconfig.storage.impermanence.systemState.reasons`"
- [X] T017 [US1] Add default system-state inventory entries for `/etc/machine-id`, `/var/lib/nixos`, `/var/lib/systemd`, conditional `/var/lib/tailscale`, and evaluated `networking.hostId` in `modules/nixos/storage/impermanence.nix` per `specs/001-integrate-impermanence/data-model.md` "Persistent System-State Inventory"; SSH host identity lives directly under `/persist/etc/ssh`
- [X] T018 [US1] Add non-empty reason assertions for every system-state file, directory, and evaluated key in `modules/nixos/storage/impermanence.nix` per `specs/001-integrate-impermanence/contracts/options.md` "`nixconfig.storage.impermanence.systemState.reasons`"
- [X] T019 [US1] Configure upstream NixOS impermanence declarations for persisted system files and directories under `nixconfig.storage.impermanence.persistRoot` in `modules/nixos/storage/impermanence.nix` per `specs/001-integrate-impermanence/research.md` "Activation requires a reviewed persistent system-state inventory"
- [X] T020 [US1] Implement initrd-stage ZFS rollback for `nixconfig.storage.impermanence.rootDataset` to `nixconfig.storage.impermanence.blankSnapshot` in `modules/nixos/storage/impermanence.nix` per `specs/001-integrate-impermanence/research.md` "Root rollback is an initrd-stage operation"
- [X] T021 [US1] Ensure initrd rollback has the required ZFS tooling and fails visibly when the dataset or blank snapshot is missing in `modules/nixos/storage/impermanence.nix` per `specs/001-integrate-impermanence/plan.md` "Root Rollback Design"
- [X] T022 [US1] Add activation or boot assertions for `/persist`, `/home`, `nixconfig.storage.impermanence.persistRoot`, and `nixconfig.storage.impermanence.userSafeHavenRoot` in `modules/nixos/storage/impermanence.nix` per `specs/001-integrate-impermanence/data-model.md` "Storage Readiness Check"
- [X] T023 [US1] Enable `nixconfig.storage.impermanence.enable = true` for shared workstation hosts in `configurations/nixos/_shared/workstation-profile.nix` while preserving `hephaestus-vm` backup-disabled behavior in `configurations/nixos/hephaestus-vm/default.nix`

### Validation for User Story 1

- [X] T024 [US1] Run `nix build .#nixosConfigurations.hephaestus-vm.config.system.build.toplevel` from `flake.nix` per `specs/001-integrate-impermanence/quickstart.md` "Static Checks"
- [ ] T025 [US1] Run `nix build .#nixosConfigurations.hephaestus.config.system.build.toplevel` and `nix build .#nixosConfigurations.apollo.config.system.build.toplevel` from `flake.nix` per `specs/001-integrate-impermanence/quickstart.md` "Static Checks"
- [X] T026 [US1] Run the `nix eval` inventory commands for `systemState.files`, `systemState.directories`, and `networking.hostId` from `specs/001-integrate-impermanence/quickstart.md` "System-State Inventory Review"
- [ ] T027 [US1] Run VM reboot validation from `specs/001-integrate-impermanence/quickstart.md` "VM Reboot Validation" and confirm `/root-should-disappear` is absent after reboot

**Checkpoint**: User Story 1 is functional and independently validated.

---

## Phase 4: User Story 2 - Curated User Safe-Haven Persistence (Priority: P2)

**Goal**: `/home/<user>` remains persistent, while declared safe-haven entries
are stored under `/persist/home/<user>` and exposed at normal home paths.

**Independent Test**: Add a declared safe-haven file and an ordinary home file,
reboot, and confirm both survive while the declared file is also present under
`/persist/home/<user>`.

### Implementation for User Story 2

- [X] T028 [US2] Implement `homeconfig.persistence.enable` defaults in `modules/home/persistence/options.nix` so embedded NixOS follows `osConfig.nixconfig.storage.impermanence.enable` and standalone Home Manager defaults to `false` per `specs/001-integrate-impermanence/contracts/options.md` "`homeconfig.persistence.enable`"
- [X] T029 [US2] Implement `homeconfig.persistence.safeHaven.enable`, `homeconfig.persistence.safeHaven.path`, `homeconfig.persistence.safeHaven.directories`, and `homeconfig.persistence.safeHaven.files` options in `modules/home/persistence/options.nix` per `specs/001-integrate-impermanence/contracts/options.md` "Home Manager Option Surface"
- [X] T030 [US2] Implement two-level enable gating and upstream `home.persistence` option availability checks in `modules/home/persistence/safe-haven.nix` per `specs/001-integrate-impermanence/spec.md` FR-013
- [X] T031 [US2] Implement safe-haven directory and file mapping from `homeconfig.persistence.safeHaven.path` to `/home/${config.me.username}/...` in `modules/home/persistence/safe-haven.nix` per `specs/001-integrate-impermanence/contracts/options.md` "`homeconfig.persistence.safeHaven.directories`"
- [X] T032 [US2] Add assertions that every safe-haven entry has a non-empty reason and no reusable module hardcodes `gorschu` in `modules/home/persistence/safe-haven.nix` per `specs/001-integrate-impermanence/spec.md` FR-009 and FR-012
- [X] T033 [US2] Add an initial declared safe-haven validation directory such as `ImpermanenceTest` with a reason in `configurations/home/gorschu.nix` per `specs/001-integrate-impermanence/quickstart.md` "VM Reboot Validation"
- [X] T034 [US2] Preserve ordinary `/home/${config.me.username}` behavior by avoiding any Home Manager or NixOS declaration that makes the live home dataset ephemeral in `modules/home/persistence/safe-haven.nix` and `modules/nixos/storage/impermanence.nix` per `specs/001-integrate-impermanence/spec.md` "Edge Cases"

### Validation for User Story 2

- [X] T035 [US2] Run `nix build .#homeConfigurations."gorschu@hephaestus".activationPackage` from `flake.nix` to validate standalone Home Manager guard behavior per `specs/001-integrate-impermanence/quickstart.md` "Static Checks"
- [X] T036 [US2] Run `nix build .#nixosConfigurations.hephaestus-vm.config.system.build.toplevel` from `flake.nix` to validate embedded Home Manager persistence per `specs/001-integrate-impermanence/quickstart.md` "Static Checks"
- [ ] T037 [US2] Run the safe-haven and ordinary-home checks from `specs/001-integrate-impermanence/quickstart.md` "VM Reboot Validation" and confirm both `/persist/home/$USER/ImpermanenceTest/declared.txt` and `$HOME/ordinary-home-persists.txt` survive reboot

**Checkpoint**: User Story 2 is functional and independently validated.

---

## Phase 5: User Story 3 - Backups Target Curated Safe-Haven Data (Priority: P3)

**Goal**: Restic backups for affected physical hosts target curated safe-haven
data and explicitly selected system-state backup paths, while preserving
existing repositories, schedules, retention, and credentials.

**Independent Test**: Evaluate backup paths for `hephaestus` and `apollo` and
confirm they include `/persist/home/gorschu`, include only selected
`systemState.backupPaths`, and do not include the full live `/home`.

### Implementation for User Story 3

- [X] T038 [US3] Update `nixconfig.storage.backup.paths` default construction in `modules/nixos/storage/restic-backup.nix` to use `/persist/home/<user>` for affected hosts instead of the full live `/home` per `specs/001-integrate-impermanence/contracts/options.md` "`nixconfig.storage.backup.paths`"
- [X] T039 [US3] Derive the safe-haven backup path in `modules/nixos/storage/restic-backup.nix` from embedded Home Manager user metadata or declared safe-haven configuration without hardcoding reusable module identity per `specs/001-integrate-impermanence/spec.md` FR-012
- [X] T040 [US3] Append only `nixconfig.storage.impermanence.systemState.backupPaths` to restic sources in `modules/nixos/storage/restic-backup.nix` per `specs/001-integrate-impermanence/contracts/options.md` "`nixconfig.storage.impermanence.systemState.backupPaths`"
- [X] T041 [US3] Preserve existing restic target repository, timer, retention, password, environment template, and SOPS secret behavior in `modules/nixos/storage/restic-backup.nix` per `specs/001-integrate-impermanence/spec.md` FR-011
- [X] T042 [US3] Remove or narrow now-obsolete broad home-directory exclude assumptions in `modules/nixos/storage/restic-excludes.txt` only where they no longer apply to `/persist/home/<user>` per `specs/001-integrate-impermanence/research.md` "Narrow restic backup sources"

### Validation for User Story 3

- [X] T043 [US3] Run `nix eval .#nixosConfigurations.hephaestus.config.nixconfig.storage.backup.paths` and `nix eval .#nixosConfigurations.apollo.config.nixconfig.storage.backup.paths` from `flake.nix` per `specs/001-integrate-impermanence/quickstart.md` "Backup Scope Validation"
- [X] T044 [US3] Run `nix eval .#nixosConfigurations.hephaestus.config.services.restic.backups.b2.repository` and `nix eval .#nixosConfigurations.apollo.config.services.restic.backups.b2.repository` from `flake.nix` per `specs/001-integrate-impermanence/quickstart.md` "Backup Scope Validation"
- [ ] T045 [US3] Run `nix build .#nixosConfigurations.hephaestus.config.system.build.toplevel` and `nix build .#nixosConfigurations.apollo.config.system.build.toplevel` from `flake.nix` to validate backup-enabled physical hosts per `specs/001-integrate-impermanence/quickstart.md` "Static Checks"

**Checkpoint**: User Story 3 is functional and independently validated.

---

## Phase 6: User Story 4 - Migration and Install Readiness (Priority: P4)

**Goal**: Operators can tell whether existing hosts are ready, require
migration, or should be reinstalled before enabling impermanence.

**Independent Test**: Review each supported workstation against required
datasets, snapshots, paths, system-state inventory, backup paths, and rollback
steps using repository documentation.

### Implementation for User Story 4

- [X] T046 [US4] Document required datasets, root snapshot, `/persist`, `/home`, `/persist/home/<user>`, and readiness blocking behavior in `docs/new-host-setup.md` per `specs/001-integrate-impermanence/quickstart.md` "Storage Readiness Review"
- [X] T047 [US4] Document migration-required versus reinstall-required outcomes and the activation-blocking conditions in `docs/new-host-setup.md` per `specs/001-integrate-impermanence/spec.md` FR-004 and FR-005
- [X] T048 [US4] Document system-state inventory review for `/etc/machine-id`, `/persist/etc/ssh/ssh_host_*`, `networking.hostId`, sops bootstrap, and host-conditional service state in `docs/new-host-setup.md` per `specs/001-integrate-impermanence/quickstart.md` "System-State Inventory Review"
- [X] T049 [US4] Document restic source changes, `/persist/home/<user>` backup scope, `systemState.backupPaths`, preserved targets, and rollback expectations in `docs/restic-backup-setup.md` per `specs/001-integrate-impermanence/quickstart.md` "Backup Scope Validation"
- [X] T050 [US4] Document rollback behavior that disables new enable gates without deleting `/home/<user>` or `/persist/home/<user>` data in `docs/restic-backup-setup.md` per `specs/001-integrate-impermanence/quickstart.md` "Rollback Validation"

### Validation for User Story 4

- [ ] T051 [US4] Run the storage readiness commands for each physical host from `specs/001-integrate-impermanence/quickstart.md` "Storage Readiness Review" before switching `configurations/nixos/hephaestus/configuration.nix` or `configurations/nixos/apollo/configuration.nix`
- [X] T052 [US4] Review `docs/new-host-setup.md` and `docs/restic-backup-setup.md` against `specs/001-integrate-impermanence/spec.md` FR-015 to confirm first activation, reboot validation, backup validation, migration/reinstall, and rollback are covered

**Checkpoint**: User Story 4 is functional and independently validated.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Final validation and cleanup across all user stories.

- [X] T053 [P] Run `rg -n "homeconfig\\.cli\\.persistence|homeconfig\\.gui\\.persistence|safeHavenPath|/home/gorschu" modules configurations specs docs -S` to verify no stale persistence option names or reusable hardcoded user paths remain in `modules/`, `configurations/`, `specs/`, or `docs/`
- [X] T054 [P] Run `rg -n "imports = .*config|config = .*imports" modules configurations -S` and manually inspect results to verify no module added `imports` inside `config` in `modules/` or `configurations/`
- [X] T055 Run `just lint` from `justfile` to format and lint changed Nix and documentation files
- [ ] T056 Run `nix build .#nixosConfigurations.hephaestus-vm.config.system.build.toplevel`, `nix build .#nixosConfigurations.hephaestus.config.system.build.toplevel`, `nix build .#nixosConfigurations.apollo.config.system.build.toplevel`, and `nix build .#homeConfigurations."gorschu@hephaestus".activationPackage` from `flake.nix`
- [ ] T057 Run VM reboot validation from `specs/001-integrate-impermanence/quickstart.md` "VM Reboot Validation" before any physical host deployment
- [ ] T058 Run physical host validation from `specs/001-integrate-impermanence/quickstart.md` "Physical Host Runtime Validation" only after `hephaestus-vm` validation succeeds
- [X] T059 Verify `git diff -- flake.nix` contains only the impermanence input/module wiring and no unrelated host or standalone Home Manager profile registration changes

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies; can start immediately.
- **Foundational (Phase 2)**: Depends on Setup completion and blocks all user
  stories.
- **User Story 1 (Phase 3)**: Depends on Foundational; provides the boot-time
  root reset and system-state inventory needed by later runtime validation.
- **User Story 2 (Phase 4)**: Depends on Foundational; can be implemented after
  US1 scaffolding exists, and its runtime validation should run after US1 VM
  root reset works.
- **User Story 3 (Phase 5)**: Depends on Foundational and uses the US2
  safe-haven path as its primary backup source.
- **User Story 4 (Phase 6)**: Depends on Setup; documentation can be drafted in
  parallel, but final validation should reflect US1-US3 implementation.
- **Polish (Phase 7)**: Depends on all desired user stories being complete.

### User Story Dependencies

- **US1 Clean Root on Every Boot (P1)**: MVP and first runtime validation slice.
- **US2 Curated User Safe-Haven Persistence (P2)**: Requires persistence
  category scaffolding and benefits from US1 runtime validation.
- **US3 Backups Target Curated Safe-Haven Data (P3)**: Requires safe-haven path
  semantics from US2.
- **US4 Migration and Install Readiness (P4)**: Can start after Setup but must
  be finalized after US1-US3 behavior is known.

### Within Each User Story

- Options before modules that consume them.
- Assertions before host/profile enablement.
- Module implementation before host/profile validation.
- VM validation before physical host validation.
- Backup path evaluation before backup-enabled physical host runtime checks.

---

## Parallel Opportunities

- Setup tasks T002-T006 can run in parallel after T001 is understood.
- Foundational Home Manager scaffold tasks T011 and T012 can run in parallel
  with NixOS scaffold task T009 after T007 and T008 are complete.
- US1 documentation-free validation tasks T024-T026 can be prepared in parallel
  once T015-T023 are implemented.
- US2 option implementation in `modules/home/persistence/options.nix` can be
  reviewed independently from safe-haven mapping in
  `modules/home/persistence/safe-haven.nix`.
- US3 restic exclude cleanup T042 can run in parallel with restic source changes
  T038-T040 if the final backup path contract is already agreed.
- US4 documentation tasks T046-T050 can be drafted in parallel with US1-US3
  implementation and finalized during validation.

---

## Parallel Example: User Story 1

```bash
# Different files, no dependency on each other after foundation:
Task: "T020 [US1] Implement initrd-stage ZFS rollback in modules/nixos/storage/impermanence.nix"
Task: "T046 [US4] Document required datasets and readiness checks in docs/new-host-setup.md"
```

## Parallel Example: User Story 2

```bash
# Different files once the Home Manager persistence category exists:
Task: "T029 [US2] Implement safe-haven options in modules/home/persistence/options.nix"
Task: "T033 [US2] Add initial safe-haven validation directory in configurations/home/gorschu.nix"
```

## Parallel Example: User Story 3

```bash
# Different files after backup source behavior is defined:
Task: "T038 [US3] Update backup paths in modules/nixos/storage/restic-backup.nix"
Task: "T049 [US4] Document restic source changes in docs/restic-backup-setup.md"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup.
2. Complete Phase 2: Foundational.
3. Complete Phase 3: User Story 1.
4. Stop and validate root reset plus system-state persistence on
   `hephaestus-vm`.
5. Do not deploy to physical hosts until VM reboot validation passes.

### Incremental Delivery

1. Deliver US1 clean root and system-state inventory.
2. Deliver US2 safe-haven user persistence while keeping `/home/<user>`
   persistent.
3. Deliver US3 restic source narrowing.
4. Deliver US4 operator documentation for readiness, migration, reinstall, and
   rollback.
5. Run cross-cutting validation before physical deployment.

### Parallel Team Strategy

With multiple implementers:

1. Complete Setup and Foundational work together.
2. After Foundational:
   - Implementer A: US1 in `modules/nixos/storage/impermanence.nix`.
   - Implementer B: US2 in `modules/home/persistence/` and
     `configurations/home/gorschu.nix`.
   - Implementer C: US4 documentation in `docs/`.
3. Start US3 only after the US2 safe-haven path semantics are stable.

---

## Notes

- Do not import the deprecated upstream Home Manager impermanence module
  directly; import the NixOS impermanence module through workstation wiring.
- Keep `/home/<user>` persistent. Undeclared home files are outside the default
  backup source, not deleted on reboot.
- `systemState.reasons` is audit metadata and must not create persistence
  declarations by itself.
- Persisting system state for boot safety does not automatically include that
  state in restic; only `systemState.backupPaths` joins backup sources.
- Prefer `just` recipes where they exist, and use narrow Nix builds from
  `quickstart.md` before broad checks.
