# AGENTS.md

This file provides guidance to Claude Code (claude.ai/code) when working in this repository.

## Architecture Overview

This repository is a `flake-parts`-based NixOS and Home Manager configuration.
It manages NixOS hosts, Home Manager profiles, deployment helpers, secrets, and installation workflows from a single flake.

### What Actually Drives The Repository

- `flake.nix` is the composition root.
- `flake-parts.lib.mkFlake` provides the flake structure.
- NixOS hosts are registered explicitly under `flake.nixosConfigurations`.
- Standalone Home Manager profiles are registered explicitly under `flake.homeConfigurations`.
- Shared NixOS wiring lives in `commonModules` in `flake.nix`.
- A Colmena hive is exported, but it is optional deployment plumbing rather than the core architecture.
- Operational workflows are primarily exposed through `justfile` recipes.

### Module Layout

- `modules/flake/` contains flake-level modules such as formatter, dev shell, git hooks, and Neovim integration.
- `modules/nixos/` contains reusable NixOS modules grouped by domain.
- `modules/home/` contains reusable Home Manager modules and user metadata.

### Auto-Import Boundaries

Auto-import exists for module groups, not for host registration.

- `modules/home/default.nix` imports the Home Manager module groups.
- `modules/nixos/default.nix` imports the NixOS module groups.
- Directory-level `default.nix` files inside module groups auto-import sibling files and nested module groups.
- Adding a file to a module directory is usually enough for that module group to see it.
- Adding a new host or standalone Home Manager profile still requires explicit registration in `flake.nix`.

### Configuration Composition

- Host-specific NixOS entrypoints live under `configurations/nixos/<hostname>/`.
- User-specific Home Manager entrypoints live under `configurations/home/`.
- `configurations/nixos/<hostname>/default.nix` is the top-level host composition entrypoint.
- `configurations/nixos/<hostname>/configuration.nix` contains machine-specific settings such as hostname, hardware, and state version.
- `configurations/home/gorschu.nix` imports the shared Home Manager module tree through `inputs.self.homeModules.default` and sets user-specific options.

## Common Commands

### Primary Workflow Commands

```bash
just           # List available commands
just update    # Update flake inputs
just lint      # Format Nix files with nix fmt
just check     # Run nix flake check
just dev       # Enter the dev shell
```

### Deployment And Provisioning

```bash
just install <target> HOST=hephaestus         # Install NixOS remotely with nixos-anywhere
just deploy hephaestus <target>               # Deploy to an existing remote host with nixos-rebuild
just deploy-local                             # Deploy to the current NixOS host using its hostname as the flake target
just regenerate-facter                        # Regenerate facter.json for the current host
just decrypt-keys hephaestus                  # Decrypt host SSH keys in extra-files/
```

`just deploy-local` is the intended local activation path for a managed machine.
It resolves the current hostname and runs `nixos-rebuild switch --flake .#<hostname>`.

### VM Helpers

```bash
just vm-create NAME=nixos-test
just vm-destroy NAME=nixos-test
just vm-info NAME=nixos-test
just vm-console NAME=nixos-test
```

### Direct Nix Commands

```bash
nix fmt
nix flake check
nix develop
nix build .#nixosConfigurations.hephaestus.config.system.build.toplevel
nix build .#homeConfigurations."gorschu@hephaestus".activationPackage
```

## Configuration Patterns

### Two-Level Enable Pattern

Home Manager modules use a two-level enable pattern:

1. Category level: `homeconfig.cli.enable` or `homeconfig.gui.enable`
2. Subcategory level: `homeconfig.cli.development.enable`, `homeconfig.cli.editor.enable`, `homeconfig.cli.shell.enable`, `homeconfig.cli.system.enable`, `homeconfig.gui.browsers.enable`, or `homeconfig.gui.desktop.enable`

Individual Home Manager modules are expected to check both levels with `lib.mkIf (cfg.enable && cfg.subcategory.enable)`.

NixOS modules are less uniform. Some use category-level enables such as `nixconfig.gui.enable`, while others define their own module-level enables such as `nixconfig.storage.zfs.enable`, `nixconfig.networking.tailscale.enable`, `nixconfig.ssh.enable`, `nixconfig.gnome.enable`, or `nixconfig._1password.enable`.

See `MODULES.md` for the detailed module conventions.

## Adding New Modules

Always read `MODULES.md` and refer to `modules/home/TEMPLATE.nix` before adding a new Home Manager module.

### Home Manager CLI Module

```bash
# 1. Create the module file in the appropriate module group
vim modules/home/cli/mycategory/mymodule.nix

# 2. If the module needs a new subcategory toggle, update:
vim modules/home/cli/options.nix
```

Follow these rules:

- Use `cfg = config.homeconfig.cli`
- Guard config with `lib.mkIf (cfg.enable && cfg.mycategory.enable)`
- Use `config.me.*` for username, fullname, email, and SSH keys

### Home Manager GUI Module

```bash
# 1. Create the module file in the GUI tree
vim modules/home/gui/mycategory/mymodule.nix

# 2. If the module needs a new subcategory toggle, update:
vim modules/home/gui/options.nix
```

Follow these rules:

- Use `cfg = config.homeconfig.gui`
- Guard config with `lib.mkIf (cfg.enable && cfg.mycategory.enable)`

### NixOS Module

```bash
# 1. Create the module file in the appropriate NixOS group
vim modules/nixos/mycategory/mymodule.nix
```

Follow these rules:

- Define options close to the owning module unless a shared options file already exists
- Guard configuration with the relevant enable option
- Let the nearest directory `default.nix` import tree pick the file up automatically

### Enabling Modules In Configurations

```nix
# configurations/home/gorschu.nix
homeconfig.gui.enable = true;
homeconfig.cli.mycategory.enable = true;

# configurations/nixos/<hostname>/default.nix
nixconfig.mycategory.enable = true;
```

## Critical Rules

1. Never place `imports` inside a `config` block.
2. For Home Manager modules, check both category and subcategory enables.
3. Use `config.me.*` for shared user metadata.
4. Let module-group `default.nix` files handle imports instead of manually wiring sibling modules.
5. Register hosts and standalone Home Manager profiles explicitly in `flake.nix`.

## Important Files

- `flake.nix` - source of truth for flake composition, host registration, shared modules, and outputs
- `justfile` - main operational workflow entrypoint
- `MODULES.md` - detailed module architecture and contribution guide
- `modules/home/TEMPLATE.nix` - template for Home Manager modules
- `modules/flake/toplevel.nix` - flake-level formatter setup
- `modules/flake/devshell.nix` - development shell tools
- `modules/home/me.nix` - user metadata consumed across Home Manager modules
- `modules/home/cli/options.nix` - CLI category and subcategory toggles
- `modules/home/gui/options.nix` - GUI category and subcategory toggles
- `configurations/home/gorschu.nix` - user profile entrypoint
- `configurations/nixos/hephaestus/default.nix` - host entrypoint
- `configurations/nixos/hephaestus/configuration.nix` - machine-specific NixOS settings
