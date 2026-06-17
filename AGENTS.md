# AGENTS.md

This file provides guidance to Claude Code (claude.ai/code) when working in this repository.

## Architecture

A `flake-parts`-based NixOS and Home Manager configuration. `flake.nix` is the composition root: it wires shared NixOS modules, registers every NixOS host under `nixosConfigurations`, registers every standalone Home Manager profile under `homeConfigurations`, and exports `nixosModules.default` / `homeModules.default`.

Operational workflows (build, check, deploy, VM lifecycle, secret handling) are exposed through `justfile` recipes. Treat `just` as the canonical entrypoint; prefer it over raw `nix`/`nixos-rebuild` invocations when a recipe exists.

## Layout

- `flake.nix` — composition root. Hosts and standalone HM profiles are registered here explicitly. Adding a new host or HM profile requires editing this file.
- `modules/flake/` — flake-level modules (formatter, dev shell, git hooks, editor integrations).
- `modules/nixos/` — reusable NixOS modules grouped by domain.
- `modules/home/` — reusable Home Manager modules and user metadata.
- `configurations/nixos/<hostname>/` — per-host entrypoint and machine-specific settings.
- `configurations/nixos/_shared/` — cross-host workstation wiring (profile, disk layout) imported by host entrypoints.
- `configurations/home/` — standalone Home Manager profile entrypoints.

Within `modules/`, each directory's `default.nix` auto-imports its siblings and nested subgroups. **Dropping a new file into a module group is enough to wire it up.** Host and profile registration is the only manual wiring step.

## Conventions

### Home Manager: two-level enable pattern

Home Manager modules sit under a category (`homeconfig.cli`, `homeconfig.gui`) with subcategories beneath each. A module must guard its config with **both** levels:

```nix
config = lib.mkIf (cfg.enable && cfg.<subcategory>.enable) { … };
```

Category and subcategory toggles live in the corresponding `options.nix` for the category. When adding a module that warrants a new subcategory, add the toggle there. Defaults: CLI category on, GUI category off, subcategories on when their category is on.

### NixOS: per-module enables

NixOS modules are not strictly two-level. Each module defines its own `nixconfig.<thing>.enable` (and any related sub-options) close to the module that owns them. When a module depends on another being enabled, express it as an `assertions` entry with a clear message rather than silently coupling.

When extending an existing group, follow the shape already used by the nearest module rather than imposing a new abstraction.

### User metadata

Read user identity (`username`, `fullname`, `email`, `sshKeys`, etc.) from `config.me.*`. Never hardcode these in modules.

### Catppuccin theming

When adding or changing Catppuccin themes, consult the Catppuccin Nix flake/modules first and prefer its Home Manager/NixOS options over hand-rolled theme files when an option exists. Example option reference: `https://nix.catppuccin.com/options/main/home/catppuccin.vicinae/`.

### Composition over inheritance

Prefer small modules organized by function over per-host modules. Per-host files should compose shared modules and toggle options, not duplicate logic.

## Critical rules

1. **Never put `imports` inside a `config` block.** `imports` belongs at the top level of the module.
2. **Home Manager modules check both enable layers** (category and subcategory).
3. **User metadata lives under `config.me.*`** — do not hardcode.
4. **Let directory `default.nix` files handle imports.** Do not manually list sibling modules in a parent file.
5. **Register hosts and standalone HM profiles explicitly in `flake.nix`.** Auto-import does not cover registration.
6. **Match existing option shapes.** Read nearby modules before introducing a new convention.

## Workflow

- `just` — list recipes.
- `just lint` / `just check` — formatting and `nix flake check`.
- `just deploy-local` — switch the current NixOS host to its matching `nixosConfigurations` entry.
- `just deploy <host> <target>` — remote `nixos-rebuild switch`.
- `just install <target> HOST=<host>` — first-time install via `nixos-anywhere`.
- VM lifecycle (`vm-create`, `vm-destroy`, `vm-info`, `vm-console`, …) drives the Terraform/libvirt rig under `terraform/`.
- Secret handling uses `sops-nix`; host SSH keys are staged via `just decrypt-keys <host>`.

When testing a slice of changes, prefer the narrowest applicable build target (`nix build .#nixosConfigurations.<host>.config.system.build.toplevel` or `nix build .#homeConfigurations."<user>@<host>".activationPackage`) over a full `nix flake check`.

## Adding things

- **New module:** drop the file into the appropriate `modules/{home,nixos}/<group>/` subtree. Use a nearby module as the template. Add a toggle in the category's `options.nix` only when introducing a new HM subcategory.
- **New host:** create `configurations/nixos/<hostname>/{default,configuration}.nix`, then register it in `flake.nix` alongside the existing hosts. Reuse `_shared/` wiring where applicable.
- **New standalone HM profile:** create the entrypoint in `configurations/home/` and register it under `homeConfigurations` in `flake.nix`.

See `MODULES.md` for the deeper rationale behind these conventions.
