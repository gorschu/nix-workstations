{
  description = "NixOS and Home Manager configuration";

  nixConfig = {
    extra-substituters = [
      "https://cache.numtide.com"
      "https://noctalia.cachix.org"
    ];
    extra-trusted-public-keys = [
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
      "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
    ];
  };

  inputs = {
    # Core inputs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    flake-parts.url = "github:hercules-ci/flake-parts";

    # Software inputs
    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";
    nixvim = {
      url = "github:nix-community/nixvim";
      # Follow our nixpkgs (single-nixpkgs setup). nixvim warns about this; we
      # silence it by setting programs.nixvim.nixpkgs.source explicitly in
      # modules/home/cli/neovim/default.nix. NOTE: dropping this follows breaks
      # eval, because nixvim's own pinned nixpkgs lags ours and trips the
      # `lib.systems.elaborate: linux-kernel has been removed` 26.11 change.
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.follows = "flake-parts";
    };

    # Noctalia — desktop shell (v5). Follow this repo's nixpkgs for consistency.
    # Upstream notes that omitting this follows can improve noctalia.cachix.org
    # cache hits, so revisit this if local Noctalia builds become expensive.
    noctalia = {
      url = "github:noctalia-dev/noctalia";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # System configuration inputs
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    impermanence.url = "github:nix-community/impermanence";
    impermanence.inputs.nixpkgs.follows = "nixpkgs";
    nixos-facter-modules.url = "github:numtide/nixos-facter-modules";
    sops-nix.url = "github:Mic92/sops-nix";

    # AI coding agents — daily-updated packages for codex, claude-code, copilot-cli, etc.
    llm-agents.url = "github:numtide/llm-agents.nix";

    # Catppuccin theme modules for NixOS/Home Manager integrations.
    catppuccin = {
      url = "github:catppuccin/nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # KDE Plasma declarative Home Manager configuration
    plasma-manager.url = "github:nix-community/plasma-manager";
    plasma-manager.inputs.nixpkgs.follows = "nixpkgs";
    plasma-manager.inputs.home-manager.follows = "home-manager";

    # Declarative Flatpak package management
    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=latest";

    # Development tooling
    git-hooks.url = "github:cachix/git-hooks.nix";
    git-hooks.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs@{
      nixpkgs,
      home-manager,
      flake-parts,
      ...
    }:
    let
      localPackages = pkgs: import ./packages { inherit pkgs; };
      localOverlay = final: _: localPackages final;

      # Shared NixOS modules applied to every host
      commonModules = [
        ./modules/nixos
        home-manager.nixosModules.home-manager
        inputs.nix-flatpak.nixosModules.nix-flatpak
        {
          nixpkgs.overlays = [
            localOverlay
            inputs.llm-agents.overlays.default
          ];
        }
        {
          home-manager = {
            extraSpecialArgs = { inherit inputs; };
            sharedModules = [
              inputs.sops-nix.homeManagerModules.sops
              inputs.plasma-manager.homeModules.plasma-manager
              inputs.catppuccin.homeModules.catppuccin
            ];
          };
        }
      ];
    in
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        ./modules/flake/devshell.nix
        ./modules/flake/git-hooks.nix
        ./modules/flake/neovim.nix
        ./modules/flake/packages.nix
        ./modules/flake/toplevel.nix
      ];

      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      flake = {
        nixosConfigurations = {
          hephaestus = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            specialArgs = { inherit inputs; };
            modules = commonModules ++ [ ./configurations/nixos/hephaestus/default.nix ];
          };

          hephaestus-vm = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            specialArgs = { inherit inputs; };
            modules = commonModules ++ [ ./configurations/nixos/hephaestus-vm/default.nix ];
          };

          apollo = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            specialArgs = { inherit inputs; };
            modules = commonModules ++ [ ./configurations/nixos/apollo/default.nix ];
          };
        };

        # Standalone Home Manager profile (for non-NixOS systems)
        homeConfigurations = {
          "gorschu@hephaestus" = home-manager.lib.homeManagerConfiguration {
            pkgs = import nixpkgs {
              system = "x86_64-linux";
              config.allowUnfree = true;
              overlays = [
                localOverlay
                inputs.llm-agents.overlays.default
              ];
            };
            extraSpecialArgs = { inherit inputs; };
            modules = [
              inputs.sops-nix.homeManagerModules.sops
              inputs.plasma-manager.homeModules.plasma-manager
              inputs.catppuccin.homeModules.catppuccin
              ./modules/home
              ./configurations/home/gorschu.nix
            ];
          };
        };

        overlays.default = localOverlay;
        nixosModules.default = ./modules/nixos;
        homeModules.default = ./modules/home;
      };
    };
}
