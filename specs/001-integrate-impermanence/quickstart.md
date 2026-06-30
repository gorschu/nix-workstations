# Quickstart: Impermanence-Backed Workstation Persistence

This guide validates the implementation after tasks are complete. Run commands
from the repository root unless noted otherwise.

## Prerequisites

- The feature implementation is complete.
- `nix-community/impermanence` is present in the flake inputs.
- The target host uses the shared workstation storage profile and explicitly
  enables `nixconfig.storage.impermanence.enable`.
- For runtime reboot tests, use `hephaestus-vm` first or a physical host where
  you have console access and current backups.

## 1. Static Checks

Format the repository:

```bash
just lint
```

Expected result: formatting completes without changing unrelated files.

Check the impermanence feature build for the VM validation host:

```bash
nix build .#nixosConfigurations.hephaestus-vm.config.system.build.toplevel
```

Expected result: build succeeds and evaluates impermanence, Home Manager, ZFS,
and backup-disabled VM configuration together.

Check the physical workstation builds:

```bash
nix build .#nixosConfigurations.hephaestus.config.system.build.toplevel
nix build .#nixosConfigurations.apollo.config.system.build.toplevel
```

Expected result: both builds succeed with backup configuration enabled.

Check the standalone Home Manager profile remains safe when host storage support
is unavailable:

```bash
nix build .#homeConfigurations."gorschu@hephaestus".activationPackage
```

Expected result: standalone Home Manager evaluates with safe-haven persistence
disabled or guarded when impermanence host support is unavailable.

## 2. Storage Readiness Review

On each affected physical host, confirm the required storage layout before
switching:

```bash
sudo zfs list zroot/encrypted/ephemeral/root
sudo zfs list -t snapshot zroot/encrypted/ephemeral/root@blank
sudo zfs list zroot/encrypted/safe/persist
sudo zfs list zroot/encrypted/safe/home
test -d /persist
test -d /home
```

Expected result: every command succeeds. If any command fails, do not enable
root reset for that host until the documented migration or reinstall path is
complete.

## 3. System-State Inventory Review

Review the evaluated system-state inventory for each enabled host:

```bash
nix eval .#nixosConfigurations.hephaestus.config.nixconfig.storage.impermanence.systemState.files
nix eval .#nixosConfigurations.hephaestus.config.nixconfig.storage.impermanence.systemState.directories
nix eval .#nixosConfigurations.hephaestus.config.networking.hostId
nix eval .#nixosConfigurations.apollo.config.nixconfig.storage.impermanence.systemState.files
nix eval .#nixosConfigurations.apollo.config.nixconfig.storage.impermanence.systemState.directories
nix eval .#nixosConfigurations.apollo.config.networking.hostId
```

Expected result:

- Inventory includes `/etc/machine-id`.
- Every listed file, directory, and evaluated-state key has a non-empty reason
  in `nixconfig.storage.impermanence.systemState.reasons`.
- ZFS host identity is stable through the evaluated `networking.hostId`, or any
  implementation-introduced `/etc/hostid` or zpool cache path is classified.
- SSH host identity is rooted at `/persist/etc/ssh` and is read directly by
  sops-nix and OpenSSH; it is not part of the impermanence file inventory.
- Host-conditional service state, such as Tailscale state for enabled hosts, is
  either persisted or explicitly classified as regenerated.
- Runtime `/run/secrets` files are not treated as persistent source data.

Before enabling root reset, copy every reviewed file and directory into its
matching `/persist` backing path. `root@blank` must be a blank root dataset
snapshot created before the root dataset is populated, not a snapshot of a live
configured root filesystem.

```bash
sudo install -d -m 0755 /persist/etc /persist/var/lib
sudo cp -a /etc/machine-id /persist/etc/machine-id
sudo cp -a /var/lib/nixos /persist/var/lib/
sudo cp -a /var/lib/systemd /persist/var/lib/
```

## 4. VM Reboot Validation

Use the existing VM workflow or install test to exercise reboot behavior before
deploying to a physical workstation:

```bash
just install-vm HOST=hephaestus-vm
```

After the VM boots with the feature enabled, create test files. Replace
`ImpermanenceTest` with the declared safe-haven validation path if the
implementation chooses a different test entry.

```bash
sudo touch /root-should-disappear
mkdir -p "$HOME/ImpermanenceTest"
echo keep > "$HOME/ImpermanenceTest/declared.txt"
echo keep-home > "$HOME/ordinary-home-persists.txt"
test -e "/persist/home/$USER/ImpermanenceTest/declared.txt"
```

Reboot the VM:

```bash
sudo reboot
```

Expected result after reboot:

```bash
test ! -e /root-should-disappear
test -e "$HOME/ImpermanenceTest/declared.txt"
test -e "/persist/home/$USER/ImpermanenceTest/declared.txt"
test -e "$HOME/ordinary-home-persists.txt"
```

The ordinary home file survives because `/home/<user>` remains persistent. It
must still be outside the default restic backup source unless explicitly added
to the safe-haven scope.

## 5. Backup Scope Validation

Evaluate the configured backup paths for a physical host:

```bash
nix eval .#nixosConfigurations.hephaestus.config.nixconfig.storage.backup.paths
nix eval .#nixosConfigurations.apollo.config.nixconfig.storage.backup.paths
```

Expected result: backup paths include `/persist/home/gorschu` and selected
system persistence paths listed in
`nixconfig.storage.impermanence.systemState.backupPaths`. They do not include
the full live `/home` directory.

Confirm existing backup targets still evaluate:

```bash
nix eval .#nixosConfigurations.hephaestus.config.services.restic.backups.b2.repository
nix eval .#nixosConfigurations.apollo.config.services.restic.backups.b2.repository
```

Expected result: repository URLs still use the existing host-specific target
scheme.

## 6. Physical Host Runtime Validation

After VM validation passes, switch one physical host through the normal
workflow:

```bash
just deploy-local
```

Create the same root, safe-haven, and ordinary home test files from the VM
validation section, reboot, and verify the same expected outcomes.

Also confirm SSH and secret bootstrap still work after reboot:

```bash
systemctl status sshd.service
systemctl status sops-nix.service
test -r /run/secrets/gorschu-age-key
```

Expected result: SSH host identity remains stable, sops-nix succeeds, and the
Home Manager user age key is regenerated under `/run/secrets`.

## 7. Rollback Validation

If rollback is needed, disable the new impermanence enable gates and switch the
host back through the normal deployment workflow.

Expected result:

- Future boots stop resetting root through the new feature.
- Persistent `/home/<user>` data remains on disk.
- Curated safe-haven data remains under `/persist/home/<user>`.
- Backup paths can be returned to the previous source scope without deleting
  persisted data.

## Troubleshooting

- Missing ZFS dataset or blank snapshot: stop and follow the migration or
  reinstall documentation before enabling root reset.
- Missing `/persist/etc/ssh/ssh_host_*` after reboot: stop; host sops
  recipients may no longer match and secret decryption can fail.
- Missing or changed machine identity: inspect `/etc/machine-id` persistence.
- Declared safe-haven path missing after reboot: inspect the persistence
  declaration and systemd units for the corresponding bind or link.
- Ordinary home path missing after reboot: inspect the `/home` dataset mount;
  ordinary home data is not supposed to be ephemeral in this feature.
- Backup includes unwanted data: inspect `nixconfig.storage.backup.paths` and
  remove broad live-home paths from the enabled host configuration.
