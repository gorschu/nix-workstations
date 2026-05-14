# Module Architecture Guide

This document describes the module structure, conventions, and patterns used in this flake-parts-based NixOS and Home Manager configuration.

## Directory Structure

```text
modules/
├── flake/                 # Flake-level modules
├── home/                  # Home Manager modules
│   ├── default.nix
│   ├── me.nix
│   ├── sops.nix
│   ├── TEMPLATE.nix
│   ├── cli/
│   │   ├── default.nix
│   │   ├── options.nix
│   │   ├── ai-agents.nix
│   │   ├── direnv.nix
│   │   ├── gc.nix
│   │   ├── git.nix
│   │   ├── nix-index.nix
│   │   ├── nix.nix
│   │   ├── packages.nix
│   │   ├── shell.nix
│   │   ├── ssh.nix
│   │   ├── xdg.nix
│   │   └── neovim/
│   │       ├── default.nix
│   │       └── nixvim.nix
│   └── gui/
│       ├── default.nix
│       ├── options.nix
│       ├── fonts.nix
│       ├── terminals.nix
│       ├── xdg.nix
│       └── browsers/
│           ├── default.nix
│           └── firefox.nix
└── nixos/                 # NixOS modules
    ├── default.nix
    ├── core/
    ├── networking/
    ├── storage/
    ├── gui/
    └── virt/
```

## Composition Model

This repository uses `flake-parts` to structure the flake, but host and profile registration is still explicit.

- `flake.nix` defines `nixosConfigurations`, `homeConfigurations`, and the exported Colmena hive.
- `modules/home/default.nix` and `modules/nixos/default.nix` import top-level module groups.
- Directory `default.nix` files inside module groups auto-import sibling files and nested subgroups.
- Host definitions under `configurations/nixos/` and standalone Home Manager profiles under `configurations/home/` are registered manually in `flake.nix`.

## Two-Level Enable Pattern

Home Manager modules use a two-level enable pattern for granular control.

### Category Level

- `homeconfig.cli.enable`
- `homeconfig.gui.enable`

### Subcategory Level

- `homeconfig.cli.development.enable`
- `homeconfig.cli.editor.enable`
- `homeconfig.cli.shell.enable`
- `homeconfig.cli.system.enable`
- `homeconfig.gui.browsers.enable`
- `homeconfig.gui.desktop.enable`

Individual Home Manager modules should check both levels:

```nix
config = lib.mkIf (cfg.enable && cfg.subcategory.enable) {
  # configuration here
};
```

### Defaults

- CLI category: enabled by default
- GUI category: disabled by default
- Home Manager subcategories: enabled by default unless explicitly disabled

### NixOS Enable Pattern

NixOS modules in this repository are not uniformly modeled as a strict two-level tree.
Common patterns include:

- `nixconfig.gui.enable`
- `nixconfig.storage.zfs.enable`
- `nixconfig.storage.backup.enable`
- `nixconfig.networking.tailscale.enable`
- `nixconfig.ssh.enable`
- `nixconfig.gnome.enable`
- `nixconfig._1password.enable`
- `nixconfig.virt.qemuGuest.enable`
- `nixconfig.virt.virtioDiskLinks.enable`

When extending NixOS modules, follow the option shape already used by the nearest module group instead of forcing a uniform abstraction that the current repo does not use.

## Module Template

### Home Manager Template

Use `modules/home/TEMPLATE.nix` as the starting point for new Home Manager modules.

Key expectations:

- Set `cfg = config.homeconfig.cli` or `cfg = config.homeconfig.gui`
- Add subcategory toggles in `modules/home/cli/options.nix` or `modules/home/gui/options.nix` when needed
- Guard the configuration with both category and subcategory enables
- Use `config.me.*` for shared user metadata

### NixOS Template

There is no single dedicated NixOS template file in this repository.
Use a nearby module in the same category as the template and define options close to the owning module.

## Options Organization

### Centralized Home Manager Options

Home Manager category toggles live in separate files:

- `modules/home/cli/options.nix`
- `modules/home/gui/options.nix`

Use this pattern when a category has multiple subcategories that should be enabled or disabled consistently.

### Inline Module Options

Many NixOS modules define options directly in the owning file. Examples include:

- `modules/nixos/storage/restic-backup.nix`
- `modules/nixos/storage/zfs.nix`
- `modules/nixos/networking/tailscale.nix`
- `modules/nixos/core/ssh.nix`

Use this pattern when a module owns its own options and they are not shared across a larger category toggle file.

## Auto-Import Pattern

There are three distinct import layers in this repository.

### 1. Top-Level Module Group Imports

These files wire the major module groups together:

- `modules/home/default.nix`
- `modules/nixos/default.nix`

### 2. Directory-Level Auto-Import

Many directory `default.nix` files auto-import sibling files and nested groups with a pattern like this:

```nix
let
  inherit (builtins) readDir attrNames filter;
in
{
  imports = map (fn: ./${fn}) (filter (fn: fn != "default.nix") (attrNames (readDir ./.)));
}
```

Examples include:

- `modules/home/cli/default.nix`
- `modules/home/gui/default.nix`
- `modules/home/gui/browsers/default.nix`
- `modules/nixos/core/default.nix`
- `modules/nixos/networking/default.nix`
- `modules/nixos/storage/default.nix`
- `modules/nixos/gui/default.nix`
- `modules/nixos/virt/default.nix`

### 3. Manual Host And Profile Registration

Auto-import does not register hosts or profiles.

- `flake.nix` explicitly declares `nixosConfigurations`
- `flake.nix` explicitly declares `homeConfigurations`
- `flake.nix` explicitly exports the Colmena hive

## Critical Rules

### 1. Never Put `imports` Inside `config`

Wrong:

```nix
{
  config = lib.mkIf cfg.enable {
    imports = [ ./something.nix ];
  };
}
```

Correct:

```nix
{
  imports = [ ./something.nix ];

  config = lib.mkIf cfg.enable {
    # configuration here
  };
}
```

### 2. For Home Manager Modules, Check Both Enable Layers

```nix
config = lib.mkIf (cfg.enable && cfg.subcategory.enable) {
  # configuration
};
```

### 3. User Metadata Lives Under `me.*`

Use `config.me.*` for shared user data:

- `config.me.username`
- `config.me.fullname`
- `config.me.email`
- `config.me.sshKeys`

The `me` module is defined in `modules/home/me.nix` and imported at the top level of the Home Manager module tree.

## Adding New Modules

### 1. Home Manager CLI Module

```bash
touch modules/home/cli/mycategory/mymodule.nix
```

- Start from `modules/home/TEMPLATE.nix`
- Add a new subcategory toggle to `modules/home/cli/options.nix` if needed
- Let the nearest `default.nix` import tree pick the file up

### 2. Home Manager GUI Module

```bash
touch modules/home/gui/mycategory/mymodule.nix
```

- Start from `modules/home/TEMPLATE.nix`
- Add a new subcategory toggle to `modules/home/gui/options.nix` if needed
- Let the nearest `default.nix` import tree pick the file up

### 3. NixOS Module

```bash
touch modules/nixos/mycategory/mymodule.nix
```

- Use a nearby NixOS module as the template
- Define options in the owning file unless there is already a shared pattern for that group
- Let the nearest directory `default.nix` import tree pick the file up

### 4. Enable In Configuration

```nix
# configurations/home/gorschu.nix
homeconfig.gui.enable = true;
homeconfig.cli.mycategory.enable = true;

# configurations/nixos/<hostname>/default.nix
nixconfig.mycategory.enable = true;
```

## Module Categories

### Home Manager CLI

- `development` - Git, direnv, nix-index, and AI-agent tooling
- `editor` - Neovim and related editor configuration
- `shell` - shell and terminal-oriented configuration
- `system` - XDG, nix settings, garbage collection, and core user packages

### Home Manager GUI

- `browsers` - browser applications such as Firefox
- `desktop` - desktop integration such as XDG-related behavior

### NixOS

- `core` - base operating system settings
- `networking` - network services and connectivity modules
- `storage` - filesystems and backup configuration
- `gui` - desktop environment and GUI-specific system setup
- `virt` - virtualization and guest-specific helpers

## Testing Changes

```bash
just check
just deploy-local
nix flake check
nix build .#homeConfigurations."gorschu@hephaestus".activationPackage
nix build .#nixosConfigurations.hephaestus.config.system.build.toplevel
```

Use the narrowest applicable build or check for the slice you touched.
For applying the configuration on the current NixOS machine, use `just deploy-local`, which resolves the current hostname and switches to the matching `nixosConfigurations` entry.

## Best Practices

1. Read nearby modules before creating a new one.
2. Prefer small modules organized by function rather than by host.
3. Keep Home Manager subcategory toggles in the category `options.nix` file.
4. Keep NixOS options close to the module that owns them unless the group already centralizes them.
5. Use auto-import for module files, but do not confuse it with host registration.
6. Test incrementally with `just check` or the narrowest relevant build target.
