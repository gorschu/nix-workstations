# New Host Setup Guide

This guide walks through adding a new NixOS host to the flake. Follow every step in order.

All commands are run from the repository root unless noted otherwise.

## Overview

Adding a host requires:

1. Generating the age keys that will bootstrap user secrets on the new machine
2. Registering the host in `.sops.yaml` and `flake.nix`
3. Creating the host configuration files
4. Creating the encrypted secrets the host needs
5. Installing NixOS

---

## 1. Generate the Host User Age Keypair

Each user-host combination gets its own age keypair. The private key is stored as a sops secret (encrypted for both the admin key and the host SSH key). NixOS sops-nix decrypts it at boot so Home Manager can access user secrets without any manual key copying.

```bash
# In the dev shell
nix develop

# Generate the keypair — save BOTH lines of output
age-keygen
```

Note the output:
```
# created: ...
# public key: age1...
AGE-SECRET-KEY-1...
```

Keep the `AGE-SECRET-KEY-1...` line — you will paste it into the sops secret in step 4.

---

## 2. Register Keys in .sops.yaml

Open `.sops.yaml` and add anchors for the new host and user keys.

### Add the host SSH age key

After installing NixOS (step 5), extract the host's age public key from its SSH host key:

```bash
# On the new host after first boot
nix-shell -p ssh-to-age --run \
  'ssh-to-age < /etc/ssh/ssh_host_ed25519_key.pub'
```

Add the result to `.sops.yaml` in the `keys:` section:

```yaml
keys:
  - &admin_gorschu age1aph83gkdg83l6cf83nsdthp95dcd5natpa7527sd3p8rtlcj3dgstl502c
  - &hosts_hephaestus age1tx6wn5dtsqguqslm4cevw2crf6fgg89r6t9glxlz6hkmh4y7rqrq7p373h
  - &hosts_newhostname age1<new-host-public-key>         # ← add this
  - &users_hephaestus_gorschu age1mzqfpr6lkpjw5evkwl7fuc8wzphxe6cxg63s9kmhs99df37u2pnsawt787
  - &users_newhostname_gorschu age1<user-age-public-key>  # ← add this (from step 1)
```

> **Note**: If you are setting up the host for the first time with `just install`, you won't have the host SSH key yet. Create a placeholder and come back to this step after the first boot, then rekey the secrets.
>
> An easier approach: use `just decrypt-keys` to pre-provision the host SSH keys from the existing encrypted secrets, so you can derive the age key before first boot (see step 3b).

### Add creation rules

Add rules in `creation_rules:` for the new host. The **age-key rule must come before** the generic `secrets/users/.*` rule.

```yaml
creation_rules:
  # ... existing rules ...

  # New host: host-level secrets
  - path_regex: secrets/hosts/newhostname/[^/]+\.(yaml|json|env|ini)$
    key_groups:
      - age:
          - *admin_gorschu
          - *hosts_newhostname

  # New host: SSH host keys (admin only — host doesn't need to decrypt its own SSH keys)
  - path_regex: secrets/hosts/newhostname/ssh/ssh_host_.*_key$
    key_groups:
      - age:
          - *admin_gorschu

  # New host: user age key bootstrapping (admin + host SSH key)
  # Must be before the generic secrets/users/.* rule
  - path_regex: secrets/users/[^/]+/age/newhostname\.yaml$
    key_groups:
      - age:
          - *admin_gorschu
          - *hosts_newhostname

  # ... existing age-key and users rules ...

  # Update the generic users rule to add the new user key
  - path_regex: secrets/users/.*
    key_groups:
      - age:
          - *admin_gorschu
          - *users_hephaestus_gorschu
          - *users_newhostname_gorschu   # ← add this
```

---

## 3. Create Host Configuration

### 3a. Create the configuration directory

```bash
mkdir -p configurations/nixos/newhostname
```

Copy the structure from an existing host as a starting point:

```bash
cp configurations/nixos/hephaestus/configuration.nix configurations/nixos/newhostname/configuration.nix
cp configurations/nixos/hephaestus/disko.nix configurations/nixos/newhostname/disko.nix
```

Edit `configurations/nixos/newhostname/configuration.nix` — at minimum update:

- `networking.hostName`
- `disko.devices.disk.main.device` (disk device path)
- `system.stateVersion`
- `rootSshKeys`
- Any host-specific `nixconfig.*` settings

Create `configurations/nixos/newhostname/default.nix`:

```nix
{ inputs, ... }:
{
  imports = [
    inputs.disko.nixosModules.disko
    inputs.nixos-facter-modules.nixosModules.facter
    inputs.sops-nix.nixosModules.sops
    ./configuration.nix
  ];

  facter.reportPath = ./facter.json;

  nixconfig = {
    # Enable what this host needs
  };
}
```

A `facter.json` will be generated during install (by `--generate-hardware-config nixos-facter`).

### 3b. Create and encrypt the host SSH keys

Generate new SSH host keys:

```bash
mkdir -p secrets/hosts/newhostname/ssh

# Generate host keys (unencrypted temporarily)
ssh-keygen -t ed25519 -f secrets/hosts/newhostname/ssh/ssh_host_ed25519_key -N ""
ssh-keygen -t rsa -b 4096 -f secrets/hosts/newhostname/ssh/ssh_host_rsa_key -N ""

# Derive the host age public key from the SSH host key
nix-shell -p ssh-to-age --run \
  'ssh-to-age < secrets/hosts/newhostname/ssh/ssh_host_ed25519_key.pub'
```

Copy the age public key output and add `&hosts_newhostname` to `.sops.yaml` now (step 2).

Then encrypt the keys:

```bash
sops -e -i secrets/hosts/newhostname/ssh/ssh_host_ed25519_key
sops -e -i secrets/hosts/newhostname/ssh/ssh_host_rsa_key

# Remove the unencrypted public key files — sops stores everything in the encrypted file
rm secrets/hosts/newhostname/ssh/ssh_host_ed25519_key.pub
rm secrets/hosts/newhostname/ssh/ssh_host_rsa_key.pub
```

### 3c. Create the users secrets

```bash
# Copy from existing host and edit
cp secrets/hosts/hephaestus/users.yaml secrets/hosts/newhostname/users.yaml.plaintext
# Edit the file, then:
sops -e -i secrets/hosts/newhostname/users.yaml.plaintext
mv secrets/hosts/newhostname/users.yaml.plaintext secrets/hosts/newhostname/users.yaml
```

Or create from scratch:

```bash
sops secrets/hosts/newhostname/users.yaml
```

Add the hashed passwords:

```yaml
root/password: "$y$j9T$..."
gorschu/password: "$y$j9T$..."
```

Generate hashed passwords with:

```bash
mkpasswd -m yescrypt
```

---

## 4. Create User Age Key Secret

This secret allows NixOS sops-nix to provision the user's age key on the new machine so Home Manager sops works without any manual copying.

```bash
mkdir -p secrets/users/gorschu/age
sops secrets/users/gorschu/age/newhostname.yaml
```

Add the private key from step 1:

```yaml
age-key: AGE-SECRET-KEY-1...
```

Save and exit. sops encrypts it for both `admin_gorschu` and `hosts_newhostname`.

### Rekey existing user secrets

The new user age key needs to be added as a recipient to all existing user secrets:

```bash
sops updatekeys secrets/users/gorschu/ssh/personal.yaml
sops updatekeys secrets/users/gorschu/ssh/keys/ssh-key-seedbox_ed25519
# Repeat for any other secrets/users/gorschu/** files
```

Answer `y` when prompted.

---

## 5. Register the Host in flake.nix

Add the new host to `nixosConfigurations` in `flake.nix`:

```nix
newhostname = nixpkgs.lib.nixosSystem {
  system = "x86_64-linux";
  specialArgs = { inherit inputs; };
  modules = commonModules ++ [ ./configurations/nixos/newhostname/default.nix ];
};
```

---

## 6. Validate

```bash
just check
```

Fix any evaluation errors before proceeding.

---

## 7. Install

Decrypt the SSH host keys into the staging directory first:

```bash
just decrypt-keys newhostname
```

Then install to the target machine (booted into a NixOS installer):

```bash
just install <target-ip> HOST=newhostname
```

The installer will:
- Partition and format the disk (via disko)
- Generate `facter.json` hardware config
- Copy the SSH host keys from `extra-files/newhostname/`
- Install and activate NixOS

---

## 8. First Boot

On first boot, NixOS sops-nix (running as root) will:

1. Use the host SSH key to decrypt `secrets/users/gorschu/age/newhostname.yaml`
2. Place the user age key at `/run/secrets/gorschu-age-key` (owned by gorschu)
3. Home Manager activates and uses that key to decrypt all user secrets (SSH keys, configs, etc.)

No manual steps are needed on the new machine.

---

## Appendix: .sops.yaml Anchor Naming Conventions

| Key type | Anchor name pattern | Example |
|---|---|---|
| Admin key | `admin_<username>` | `admin_gorschu` |
| Host SSH age key | `hosts_<hostname>` | `hosts_hephaestus` |
| Per-host user age key | `users_<hostname>_<username>` | `users_hephaestus_gorschu` |
