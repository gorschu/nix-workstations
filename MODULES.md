# Module Architecture Guide

This document describes the module structure, conventions, and patterns used in this nixos-unified configuration.

## Directory Structure

```
modules/
├── flake/           # Flake-level modules (toplevel, devshell)
├── nixos/          # NixOS system modules
│   ├── core/       # Core system functionality
│   ├── storage/    # Storage and backup
│   ├── gui/        # GUI/desktop environment
│   └── virt/       # Virtualization
└── home/           # home-manager user modules
    ├── me.nix      # User metadata (always loaded)
    ├── cli/        # Command-line tools and config
    │   ├── options.nix
    │   ├── default.nix
    │   ├── development/
    │   ├── editor/
    │   ├── shell/
    │   └── system/
    └── gui/        # GUI applications and desktop
        ├── options.nix
        ├── default.nix
        ├── browsers/
        └── desktop/
```

## Two-Level Enable Pattern

All modules use a **two-level enable pattern** for granular control:

1. **Category level** - Master switch for entire category
   - `homeconfig.cli.enable` - All CLI modules
   - `homeconfig.gui.enable` - All GUI modules
   - `nixconfig.gui.enable` - GUI system modules
   - `nixconfig.storage.enable` - Storage modules

2. **Subcategory level** - Fine-grained control within category
   - `homeconfig.cli.development.enable` - Dev tools
   - `homeconfig.cli.editor.enable` - Neovim
   - `homeconfig.gui.browsers.enable` - Web browsers
   - `nixconfig.storage.zfs.enable` - ZFS pools

Individual modules check **both** levels:
```nix
config = lib.mkIf (cfg.enable && cfg.subcategory.enable) {
  # configuration here
};
```

### Defaults

- **CLI modules**: Enabled by default (`default = true`)
  - Rationale: CLI tools are lightweight and generally useful
- **GUI modules**: Disabled by default (`default = false`)
  - Rationale: GUI apps add significant dependencies, opt-in only
- **Subcategories**: Enabled by default (`default = true`)
  - Rationale: Category switch controls everything, subcategories for fine-tuning

## Module Template

### Home-Manager Module Template

```nix
# modules/home/cli/mycategory/mymodule.nix
{ config, lib, pkgs, ... }:
let
  cfg = config.homeconfig.cli;  # or .gui for GUI modules
in
{
  # Options (only if this module has its own config)
  options.homeconfig.cli.mycategory.myoption = lib.mkOption {
    type = lib.types.str;
    default = "value";
    description = "Description of this option";
  };

  # Configuration - always wrapped in mkIf with two-level check
  config = lib.mkIf (cfg.enable && cfg.mycategory.enable) {
    home.packages = with pkgs; [ mypackage ];

    programs.myprogram = {
      enable = true;
      # ... configuration
    };

    # Use config.me.* for user metadata
    # config.me.username
    # config.me.fullname
    # config.me.email
  };
}
```

### NixOS Module Template

```nix
# modules/nixos/mycategory/mymodule.nix
{ config, lib, pkgs, ... }:
let
  cfg = config.nixconfig.mycategory;
in
{
  # Options
  options.nixconfig.mycategory = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable mycategory functionality";
    };

    myoption = lib.mkOption {
      type = lib.types.str;
      default = "value";
      description = "Description of this option";
    };
  };

  # Configuration - wrapped in mkIf
  config = lib.mkIf cfg.enable {
    # system configuration here
  };
}
```

## Options Organization

Options are organized based on complexity:

### Separate options.nix Files

Use when a category has **multiple subcategories** (e.g., cli, gui):

```nix
# modules/home/cli/options.nix
{ lib, ... }:
{
  options.homeconfig.cli = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable all CLI modules";
    };

    development.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable development tools";
    };

    editor.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable neovim editor";
    };
  };
}
```

### Inline Options

Use when a module has its **own specific options**:

```nix
# modules/nixos/storage/restic-backup.nix
{ config, lib, ... }:
{
  options.nixconfig.storage.backup = {
    enable = lib.mkOption { ... };
    bucketName = lib.mkOption { ... };
    # ... more options
  };

  config = lib.mkIf cfg.enable {
    # ...
  };
}
```

## Auto-Import Pattern

Both `modules/home/cli/default.nix` and `modules/home/gui/default.nix` use automatic discovery:

```nix
{ lib, ... }:
let
  inherit (builtins) readDir attrNames filter;
in
{
  # Import all .nix files except default.nix
  imports = map (fn: ./${fn}) (filter (fn: fn != "default.nix") (attrNames (readDir ./.)));
}
```

**Key behavior:**
- Automatically imports all `.nix` files in the directory
- Skips `default.nix` itself
- Imports subdirectories that contain `default.nix`
- No manual import management needed

## Critical Rules

### 1. Never Use imports Inside config Block

❌ **WRONG** - Causes infinite recursion:
```nix
{
  config = lib.mkIf cfg.enable {
    imports = [ ./something.nix ];
  };
}
```

✅ **CORRECT** - imports at top level:
```nix
{
  imports = [ ./something.nix ];

  config = lib.mkIf cfg.enable {
    # configuration here
  };
}
```

### 2. Always Use Two-Level Enable Checks

Individual modules must check both category and subcategory:

```nix
config = lib.mkIf (cfg.enable && cfg.subcategory.enable) {
  # configuration
};
```

### 3. User Metadata via me.*

Use `config.me.*` for user information across all modules:
- `config.me.username` - System username
- `config.me.fullname` - Full name for Git, etc.
- `config.me.email` - Email address
- `config.me.sshKeys` - SSH public keys

The `me` module is defined in `modules/home/me.nix` and always loaded.

## Adding New Modules

### 1. Home-Manager CLI Module

```bash
# Create the module file
touch modules/home/cli/mycategory/mymodule.nix

# Add subcategory option to options.nix if needed
# Edit modules/home/cli/options.nix
```

### 2. Home-Manager GUI Module

```bash
# Create the module file
touch modules/home/gui/mycategory/mymodule.nix

# Add subcategory option to options.nix if needed
# Edit modules/home/gui/options.nix
```

### 3. NixOS Module

```bash
# Create the module file
touch modules/nixos/mycategory/mymodule.nix

# No default.nix needed - modules/nixos/default.nix auto-imports
```

### 4. Enable in Configuration

```nix
# For home-manager: configurations/home/username.nix
homeconfig.cli.mycategory.enable = true;
homeconfig.gui.enable = true;  # Category-level enable

# For NixOS: configurations/nixos/hostname/default.nix
nixconfig.mycategory.enable = true;
```

## Module Categories

### Home-Manager CLI (`homeconfig.cli.*`)

- **development** - Git, direnv, nix-index, ai-agents
- **editor** - Neovim with nixvim configuration
- **shell** - Zsh, starship, tmux, terminal emulators
- **system** - XDG, garbage collection, nix settings, core packages

### Home-Manager GUI (`homeconfig.gui.*`)

- **browsers** - Firefox, Zen Browser
- **desktop** - XDG portals, MIME associations

### NixOS System (`nixconfig.*`)

- **core** - Boot, locale, networking, users
- **storage** - ZFS, restic backups
- **gui** - Desktop environments, display managers
- **virt** - Virtualization (virt-manager, Docker, etc.)

## Testing Changes

```bash
# Check flake validity
just check

# Build without activating
just build

# Activate configuration
just run

# Or with nix commands
nix flake check
nix build .#homeConfigurations."gorschu@hephaestus".activationPackage
nix build .#nixosConfigurations.hephaestus.config.system.build.toplevel
```

## Best Practices

1. **Always read existing modules** before creating new ones to maintain consistency
2. **Use lib.mkIf** for all conditional configuration
3. **Keep options separate** from config logic when you have multiple subcategories
4. **Document options** with clear descriptions
5. **Test incrementally** - add one module at a time
6. **Use auto-import** - add files to directories, don't edit default.nix
7. **Follow the two-level pattern** - category + subcategory enables
8. **Reference templates** in this document when creating new modules
