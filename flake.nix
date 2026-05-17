{
  description = "NixOS and Home Manager configuration";

  nixConfig = {
    extra-substituters = [ "https://hyprland.cachix.org" ];
    extra-trusted-public-keys = [ "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc=" ];
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
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.follows = "flake-parts";
    };

    # Hyprland — upstream flake for latest packages and NixOS/HM modules.
    # WARNING: do NOT add hyprland.inputs.nixpkgs.follows — breaks the Cachix
    # binary cache which is built against Hyprland's own nixpkgs pin.
    hyprland.url = "github:hyprwm/Hyprland";

    # System configuration inputs
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    nixos-facter-modules.url = "github:numtide/nixos-facter-modules";
    sops-nix.url = "github:Mic92/sops-nix";

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
      # Shared NixOS modules applied to every host
      commonModules = [
        ./modules/nixos
        home-manager.nixosModules.home-manager
        inputs.hyprland.nixosModules.default
        {
          home-manager = {
            extraSpecialArgs = { inherit inputs; };
            sharedModules = [ inputs.sops-nix.homeManagerModules.sops ];
          };
        }
      ];
    in
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        ./modules/flake/devshell.nix
        ./modules/flake/git-hooks.nix
        ./modules/flake/neovim.nix
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
        };

        # Standalone Home Manager profile (for non-NixOS systems)
        homeConfigurations = {
          "gorschu@hephaestus" = home-manager.lib.homeManagerConfiguration {
            pkgs = nixpkgs.legacyPackages.x86_64-linux;
            extraSpecialArgs = { inherit inputs; };
            modules = [
              inputs.sops-nix.homeManagerModules.sops
              ./modules/home
              ./configurations/home/gorschu.nix
            ];
          };
        };

        nixosModules.default = ./modules/nixos;
        homeModules.default = ./modules/home;
      };
    };
}
