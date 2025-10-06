# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Architecture Overview

This is a **nixos-unified** configuration repository that manages both NixOS system configurations and home-manager user environments using a unified flake structure.

### Key Architectural Patterns

**nixos-unified Autowiring**: The flake uses `nixos-unified.flakeModules.autoWire` which automatically discovers and wires configurations based on directory structure:
- `configurations/nixos/<hostname>/` → NixOS system configurations
- `configurations/home/<username>.nix` → home-manager user configurations
- Files in these directories are automatically discovered and built

**Module Organization**:
- `modules/flake/` - Flake-level modules (toplevel glue, devshell, neovim integration)
- `modules/nixos/` - NixOS system modules, auto-imported via `default.nix` pattern
- `modules/home/` - home-manager modules, auto-imported via `default.nix` pattern
- Each `default.nix` in module directories automatically imports all sibling `.nix` files

**Auto-import Pattern**: Both `modules/home/default.nix` and `modules/nixos/default.nix` use automatic discovery:
```nix
imports = map (fn: ./${fn}) (filter (fn: fn != "default.nix") (attrNames (readDir ./.)));
```
This means adding a new `.nix` file to these directories automatically includes it - no manual import needed.

**Configuration Composition**:
- Machine configs (e.g., `configurations/nixos/hephaestus/default.nix`) import modules via `self.nixosModules.*`
- User configs (e.g., `configurations/home/gorschu.nix`) import modules via `self.homeModules.*`
- Actual system-specific settings go in `configuration.nix` (hardware, hostname, stateVersion)

## Common Commands

**Development workflow** (via justfile):
```bash
just           # List all available commands
just update    # Update flake inputs (nix flake update)
just lint      # Format nix files (nix fmt, uses nixpkgs-fmt)
just check     # Check flake validity (nix flake check)
just dev       # Enter dev shell with just and nixd
just run       # Activate the configuration (nix run, aliases to activate package)
```

**Direct nix commands**:
```bash
nix fmt                           # Format nix files
nix flake check                   # Validate flake
nix develop                       # Enter devShell
nix run                           # Activate configuration (default package)
nix build .#nixosConfigurations.hephaestus.config.system.build.toplevel  # Build system
nix build .#homeConfigurations."gorschu@hephaestus".activationPackage    # Build home-manager config
```

## Configuration Structure

**Adding a new NixOS module**: Create `modules/nixos/<name>.nix` - it will be auto-imported and available as `self.nixosModules.<name>`.

**Adding a new home-manager module**: Create `modules/home/<name>.nix` - it will be auto-imported and available as `self.homeModules.<name>`.

**Adding a new machine**: Create `configurations/nixos/<hostname>/default.nix` with imports and `configuration.nix` for hardware/system-specific settings.

**Adding a new user**: Create `configurations/home/<username>.nix` with `me` attribute for user info and imports of `self.homeModules.*`.

**Module namespace**: The `gui` module is special - it's defined in `modules/nixos/gui/` as a directory with its own `default.nix`, making it `self.nixosModules.gui`.

## Important Files

- `flake.nix` - Flake definition with inputs (nixpkgs, home-manager, nixos-unified, nixvim, etc.)
- `modules/flake/toplevel.nix` - Top-level flake glue enabling autowiring and setting formatter/default package
- `modules/flake/devshell.nix` - Development shell with just and nixd
- `modules/home/me.nix` - Defines `me` option for user metadata used across home modules
- `configurations/home/gorschu.nix` - User configuration defining `me` values and home.stateVersion
- `configurations/nixos/hephaestus/default.nix` - Machine config importing common and gui modules
- `configurations/nixos/hephaestus/configuration.nix` - Hardware/system-specific settings
