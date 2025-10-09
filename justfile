# Like GNU `make`, but `just` rustier.
# https://just.systems/
# run `just` from this directory to see available commands

# Default command when 'just' is run without arguments
default:
  @just --list

# Decrypt SSH host keys for specific host (they are SOPS-encrypted in git)
[group('setup')]
decrypt-keys HOST:
  #!/usr/bin/env bash
  set -euo pipefail
  # Decrypt keys for specific host only
  BASE_HOST="{{HOST}}"
  BASE_HOST="${BASE_HOST%-vm}"
  for key in extra-files/${BASE_HOST}/etc/ssh/ssh_host_*_key; do
    [ -f "$key" ] || continue
    echo "Decrypting ${key}"
    sops -d -i "${key}"
    chmod 600 "${key}"
  done
  echo "SSH host keys decrypted successfully"

# Update nix flake
[group('Main')]
update:
  nix flake update

# Lint nix files
[group('dev')]
lint:
  nix fmt

# Check nix flake
[group('dev')]
check:
  nix flake check

# Manually enter dev shell
[group('dev')]
dev:
  nix develop

# Activate the configuration
[group('Main')]
run:
  nix run

# Install NixOS to remote target via nixos-anywhere
[group('deploy')]
install TARGET HOST='hephaestus' EXTRA_ARGS='':
  #!/usr/bin/env bash
  set -euo pipefail
  # Strip -vm suffix for extra-files path only (VM uses same secrets)
  BASE_HOST="{{HOST}}"
  BASE_HOST="${BASE_HOST%-vm}"

  # Decrypt SSH host keys before installation
  echo "Decrypting SSH host keys for ${BASE_HOST}..."
  just decrypt-keys {{HOST}}

  # Run nixos-anywhere
  nix run github:nix-community/nixos-anywhere -- \
    --flake .#{{HOST}} \
    --extra-files extra-files/${BASE_HOST} \
    --generate-hardware-config nixos-facter configurations/nixos/{{HOST}}/facter.json \
    --ssh-option PreferredAuthentications=password \
    {{EXTRA_ARGS}} \
    root@{{TARGET}}

# Deploy configuration updates to existing system
[group('deploy')]
deploy HOST TARGET SSH_KEY='':
  #!/usr/bin/env bash
  set -euo pipefail
  SSH_OPTS="-o IdentitiesOnly=yes"
  if [ -n "{{SSH_KEY}}" ]; then
    SSH_OPTS="$SSH_OPTS -i {{SSH_KEY}}"
  fi
  export NIX_SSHOPTS="$SSH_OPTS"
  nixos-rebuild switch --flake .#{{HOST}} --target-host root@{{TARGET}}

# Install with VM test (dry-run)
[group('deploy')]
install-vm HOST='hephaestus':
  nix run github:nix-community/nixos-anywhere -- \
    --flake .#{{HOST}} \
    --extra-files extra-files/{{HOST}} \
    --vm-test

# Create test VM with Terraform
[group('vm')]
vm-create NAME='nixos-test':
  cd terraform && terraform init && terraform apply -var="vm_name={{NAME}}"

# Create test VM with debug logging
[group('vm')]
vm-create-debug NAME='nixos-test':
  cd terraform && TF_LOG=DEBUG terraform apply -var="vm_name={{NAME}}" 2>&1 | tee terraform-debug.log

# Destroy test VM
[group('vm')]
vm-destroy NAME='nixos-test':
  cd terraform && terraform destroy -target=libvirt_domain.nixos_vm -target=libvirt_volume.vm_disk -var="vm_name={{NAME}}"

# Show VM info (including IP)
[group('vm')]
vm-info NAME='nixos-test':
  cd terraform && terraform output

# Connect to VM console
[group('vm')]
vm-console NAME='nixos-test':
  virsh -c qemu:///system console {{NAME}}

# Eject CD-ROM from VM
[group('vm')]
vm-eject-cdrom NAME='nixos-test':
  virsh -c qemu:///system change-media {{NAME}} sdb --eject

# Regenerate facter.json for current host
[group('setup')]
regenerate-facter:
  #!/usr/bin/env bash
  set -euo pipefail
  HOST=$(hostnamectl hostname)
  FACTER_PATH="configurations/nixos/${HOST}/facter.json"

  echo "Regenerating facter.json for host: ${HOST}"
  echo "Output will be written to: ${FACTER_PATH}"

  sudo nix run github:nix-community/nixos-facter > "${FACTER_PATH}"

  echo "Successfully regenerated ${FACTER_PATH}"
