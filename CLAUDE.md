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

### Two-Level Enable Pattern

All home-manager modules follow a **two-level enable pattern**:
1. **Category level** (`homeconfig.cli.enable` or `homeconfig.gui.enable`) - master switch
2. **Subcategory level** (`homeconfig.cli.development.enable`, etc.) - fine-grained control

Modules check both: `lib.mkIf (cfg.enable && cfg.subcategory.enable) { ... }`

See `MODULES.md` for detailed documentation on module architecture and patterns.

### Adding New Modules

**IMPORTANT: Always read MODULES.md and refer to modules/home/TEMPLATE.nix before creating new modules.**

**Home-manager CLI module**:
```bash
# 1. Create the module file (auto-imported by default.nix)
vim modules/home/cli/mycategory/mymodule.nix

# 2. If needed, add subcategory enable option to:
vim modules/home/cli/options.nix

# 3. Follow the template pattern:
# - Use `cfg = config.homeconfig.cli`
# - Wrap config in `lib.mkIf (cfg.enable && cfg.mycategory.enable)`
# - Reference user info via config.me.{username,fullname,email}
```

**Home-manager GUI module**:
```bash
# 1. Create the module file
vim modules/home/gui/mycategory/mymodule.nix

# 2. If needed, add subcategory enable option to:
vim modules/home/gui/options.nix

# 3. Follow the template pattern:
# - Use `cfg = config.homeconfig.gui`
# - Wrap config in `lib.mkIf (cfg.enable && cfg.mycategory.enable)`
```

**NixOS system module**:
```bash
# 1. Create the module file (auto-imported)
vim modules/nixos/mycategory/mymodule.nix

# 2. Define options.nixconfig.mycategory with enable option
# 3. Wrap config in `lib.mkIf cfg.enable { ... }`
```

**Enable in user configuration**:
```nix
# configurations/home/username.nix
homeconfig.gui.enable = true;  # Enable entire GUI category
homeconfig.cli.mycategory.enable = true;  # Enable specific subcategory
```

**Enable in machine configuration**:
```nix
# configurations/nixos/hostname/default.nix
nixconfig.mycategory.enable = true;
```

### Critical Rules

1. **Never use `imports` inside `config` blocks** - causes infinite recursion
2. **Always check both enables** in home modules: `cfg.enable && cfg.subcategory.enable`
3. **Use config.me.*** for user metadata (username, fullname, email, sshKeys)
4. **Let auto-import work** - just add .nix files to directories, no manual imports needed
5. **Reference TEMPLATE.nix** when creating new modules for correct structure

## Important Files

- `MODULES.md` - **Complete module architecture documentation** (read this first!)
- `modules/home/TEMPLATE.nix` - Template for creating new home-manager modules
- `flake.nix` - Flake definition with inputs (nixpkgs, home-manager, nixos-unified, nixvim, etc.)
- `modules/flake/toplevel.nix` - Top-level flake glue enabling autowiring and setting formatter/default package
- `modules/flake/devshell.nix` - Development shell with just and nixd
- `modules/home/me.nix` - Defines `me` option for user metadata used across home modules
- `modules/home/cli/options.nix` - CLI category and subcategory enable options
- `modules/home/gui/options.nix` - GUI category and subcategory enable options
- `configurations/home/gorschu.nix` - User configuration defining `me` values and home.stateVersion
- `configurations/nixos/hephaestus/default.nix` - Machine config importing common and gui modules
- `configurations/nixos/hephaestus/configuration.nix` - Hardware/system-specific settings
