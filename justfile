# Default command when 'just' is run without arguments
default:
  @just --list

# Decrypt SSH host keys for a host into extra-files/ staging (sources live in secrets/hosts/<host>/ssh/)
[group('setup')]
decrypt-keys HOST:
  #!/usr/bin/env bash
  set -euo pipefail
  BASE_HOST="{{HOST}}"
  BASE_HOST="${BASE_HOST%-vm}"
  dest_dir="extra-files/${BASE_HOST}/persist/etc/ssh"
  shopt -s nullglob
  keys=(secrets/hosts/${BASE_HOST}/ssh/ssh_host_*_key)
  if [ ${#keys[@]} -eq 0 ]; then
    echo "ERROR: no encrypted SSH host keys found for ${BASE_HOST} under secrets/hosts/${BASE_HOST}/ssh" >&2
    exit 1
  fi
  mkdir -p "${dest_dir}"
  for enc in "${keys[@]}"; do
    keyname="$(basename "${enc}")"
    dest="${dest_dir}/${keyname}"
    echo "Decrypting ${enc} -> ${dest}"
    sops -d "${enc}" > "${dest}"
    chmod 600 "${dest}"
    ssh-keygen -y -f "${dest}" > "${dest}.pub"
    chmod 644 "${dest}.pub"
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

  # Decrypt ZFS install-time passphrase to a temp file.
  # nixos-anywhere copies it to /tmp/zfs-passphrase on the target so disko
  # can read it during dataset creation. After creation a postCreateHook
  # flips keylocation back to prompt for subsequent boots.
  ZFS_KEY_TMP="$(mktemp -t zfs-passphrase.XXXXXX)"
  trap 'rm -f "${ZFS_KEY_TMP}"' EXIT
  chmod 600 "${ZFS_KEY_TMP}"
  sops -d --output-type binary secrets/hosts/${BASE_HOST}/zfs-passphrase > "${ZFS_KEY_TMP}"

  # Run nixos-anywhere
  nix --extra-experimental-features 'nix-command flakes' \
    run github:nix-community/nixos-anywhere -- \
    --flake .#{{HOST}} \
    --extra-files extra-files/${BASE_HOST} \
    --disk-encryption-keys /tmp/zfs-passphrase "${ZFS_KEY_TMP}" \
    --generate-hardware-config nixos-facter configurations/nixos/{{HOST}}/facter.json \
    --ssh-option PreferredAuthentications=password \
    {{EXTRA_ARGS}} \
    root@{{TARGET}}

# Deploy configuration updates to an existing system
[group('deploy')]
deploy TARGET HOST='hephaestus' SSH_KEY='':
  #!/usr/bin/env bash
  set -euo pipefail
  target="{{TARGET}}"
  host="{{HOST}}"
  ssh_key="{{SSH_KEY}}"
  target_host="root@${target}"
  if [[ "${target}" == *@* ]]; then
    target_host="${target}"
  fi

  # nixos-rebuild creates SSH control sockets under TMPDIR. Long nix-shell
  # temp paths can exceed Unix socket path limits, so force a short base path.
  short_tmp="/tmp/nrb-$(id -u)"
  install -d -m 700 "${short_tmp}"
  export TMPDIR="${short_tmp}"

  SSH_OPTS="-o ControlMaster=auto -o ControlPersist=60 -o ControlPath=${short_tmp}/ssh-%C"
  if [ -n "${ssh_key}" ]; then
    SSH_OPTS="${SSH_OPTS} -o IdentitiesOnly=yes -i ${ssh_key}"
  fi

  export NIX_SSHOPTS="$SSH_OPTS"
  nixos-rebuild switch --flake ".#${host}" --target-host "${target_host}"

# Deploy configuration to localhost
[group('deploy')]
deploy-local HOST='':
  #!/usr/bin/env bash
  set -euo pipefail
  host="{{HOST}}"
  if [ -z "${host}" ]; then
    host="$(hostnamectl hostname)"
  fi
  short_tmp="/tmp/nrb-$(id -u)"
  install -d -m 700 "${short_tmp}"
  export TMPDIR="${short_tmp}"
  echo "Deploying configuration for host: ${host}"
  sudo nixos-rebuild switch --flake ".#${host}"

# Deploy configuration to localhost and activate it on next reboot
[group('deploy')]
deploy-local-reboot HOST='':
  #!/usr/bin/env bash
  set -euo pipefail
  host="{{HOST}}"
  if [ -z "${host}" ]; then
    host="$(hostnamectl hostname)"
  fi
  short_tmp="/tmp/nrb-$(id -u)"
  install -d -m 700 "${short_tmp}"
  export TMPDIR="${short_tmp}"
  echo "Deploying configuration for host: ${host} on next reboot"
  sudo nixos-rebuild boot --flake ".#${host}"

# Install with VM test (dry-run)
[group('deploy')]
install-vm HOST='hephaestus':
  #!/usr/bin/env bash
  set -euo pipefail
  BASE_HOST="{{HOST}}"
  BASE_HOST="${BASE_HOST%-vm}"
  just decrypt-keys {{HOST}}
  nix run github:nix-community/nixos-anywhere -- \
    --flake .#{{HOST}} \
    --extra-files extra-files/${BASE_HOST} \
    --vm-test

# Create test VM with Terraform
[group('vm')]
vm-create NAME='nixos-test':
  cd terraform && tofu init && tofu apply -var="vm_name={{NAME}}"

# Create test VM with debug logging
[group('vm')]
vm-create-debug NAME='nixos-test':
  cd terraform && TF_LOG=DEBUG tofu apply -var="vm_name={{NAME}}" 2>&1 | tee terraform-debug.log

# Destroy test VM
[group('vm')]
vm-destroy NAME='nixos-test':
  cd terraform && tofu destroy -target=libvirt_domain.nixos_vm -target=libvirt_volume.vm_disk -var="vm_name={{NAME}}"

[private]
_vm-refresh:
  @cd terraform && tofu refresh -var-file=terraform.tfvars > /dev/null

# Show VM info (including IP)
[group('vm')]
vm-info NAME='nixos-test': _vm-refresh
  cd terraform && tofu output

# SSH into VM as root
[group('vm')]
vm-ssh NAME='nixos-test':
  #!/usr/bin/env bash
  set -euo pipefail
  just _vm-refresh
  IP=$(cd terraform && tofu output -raw vm_ip)
  ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR -o PreferredAuthentications=password -o PubkeyAuthentication=no root@${IP}

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
