# Module Architecture Guide

This document describes the conventions and patterns that govern modules in this `flake-parts`-based NixOS and Home Manager configuration. It is the rationale companion to `AGENTS.md`.

## Composition model

`flake.nix` is the only place that performs explicit wiring of hosts and standalone Home Manager profiles. Everything else flows from auto-import:

- `modules/{home,nixos}/default.nix` import their top-level groups.
- Each group's `default.nix` auto-imports every sibling and nested subgroup via a small `readDir` snippet.
- Shared NixOS wiring applied to every host is bundled in `commonModules` inside `flake.nix`.
- Cross-host workstation wiring (profile, disk layout) lives in `configurations/nixos/_shared/` and is imported by host entrypoints that want it.

This means: dropping a file into a module group makes it visible to every host or profile that pulls in that group. The only manual step is registering a new host or HM profile in `flake.nix`.

## Enable patterns

### Home Manager: two-level

Home Manager organizes modules under a category (`homeconfig.cli`, `homeconfig.gui`), each with subcategories. A module guards its `config` block with both layers:

```nix
config = lib.mkIf (cfg.enable && cfg.<subcategory>.enable) { … };
```

Toggles for a category live in that category's `options.nix` so they can be reasoned about in one place. Default posture: CLI on, GUI off, subcategories on once their category is on.

### NixOS: per-module

NixOS modules in this repo are deliberately not forced into a uniform tree. Each module exposes its own `nixconfig.<thing>.enable` (plus any sub-options) and defines those options close to the module that owns them. When a feature depends on another, express the dependency with `assertions` carrying a clear message rather than coupling silently.

When extending a NixOS group, follow the shape already used by the nearest module. Do not introduce a uniform abstraction over modules that have intentionally diverged.

## Options placement

- **Centralize** when a category has multiple subcategories that should be reasoned about together (the Home Manager category `options.nix` files).
- **Inline** when a module owns its options and they are not shared (the typical NixOS module).

Pick the placement that minimizes lookup distance for a future reader.

## User metadata

Shared user identity is read from `config.me.*`. The `me` module is loaded at the top of the Home Manager module tree. Modules must not hardcode usernames, emails, or SSH keys.

## Critical rules

### Never put `imports` inside `config`

```nix
# Wrong
{ config = lib.mkIf cfg.enable { imports = [ ./x.nix ]; }; }

# Right
{ imports = [ ./x.nix ]; config = lib.mkIf cfg.enable { … }; }
```

### Home Manager guards both enable layers

A module silently inheriting only the category enable will activate even when its subcategory is off.

### Trust auto-import

Do not maintain a manual list of sibling modules in a parent `default.nix` when the group already auto-imports. Adding such a list creates two sources of truth and drifts.

### Register hosts and profiles explicitly

Auto-import does not register anything under `nixosConfigurations` or `homeConfigurations`. Edit `flake.nix` when adding a host or standalone HM profile.

## Adding a module

1. Decide whether it is Home Manager or NixOS, and which group it belongs to.
2. Drop the file into that group. Start from a nearby module (or `modules/home/TEMPLATE.nix` for Home Manager).
3. Wire its enable:
   - Home Manager: add a subcategory toggle in the category's `options.nix` if needed; otherwise reuse an existing subcategory.
   - NixOS: define the option close to the module unless the group already centralizes options.
4. Toggle it on per-host or per-profile in `configurations/`.

No parent `default.nix` edits should be necessary unless you are introducing a new module group.

## Adding a host

1. Create `configurations/nixos/<hostname>/{default,configuration}.nix`. Reuse `_shared/` wiring where the host fits the shared workstation shape.
2. Register the host under `nixosConfigurations` in `flake.nix`, applying `commonModules`.
3. Generate or stage any required artifacts (facter output, decrypted host keys) via the appropriate `justfile` recipe.

## Testing changes

Prefer the narrowest applicable target:

- `nix build .#homeConfigurations."<user>@<host>".activationPackage`
- `nix build .#nixosConfigurations.<host>.config.system.build.toplevel`
- `just check` for a full `nix flake check`.
- `just deploy-local` to switch the current machine to its matching configuration.

## Best practices

1. Read nearby modules before introducing a new one.
2. Prefer many small modules organized by function over per-host modules.
3. Keep Home Manager subcategory toggles in the category `options.nix`.
4. Keep NixOS options close to the module that owns them unless the group already centralizes them.
5. Use auto-import for module files; never confuse it with host registration.
6. Test incrementally with the narrowest relevant build target.
