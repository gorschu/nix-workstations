{
  description = "NixOS configuration with home-manager and Colmena deployment";

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

    # System configuration inputs
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    nixos-facter-modules.url = "github:numtide/nixos-facter-modules";
    sops-nix.url = "github:Mic92/sops-nix";

    # Development tooling
    git-hooks.url = "github:cachix/git-hooks.nix";
    git-hooks.inputs.nixpkgs.follows = "nixpkgs";

    # Deployment tooling
    colmena.url = "github:zhaofengli/colmena";
    colmena.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      home-manager,
      flake-parts,
      colmena,
      ...
    }:
    let
      # Add self to inputs for easier access
      inputs' = inputs // {
        inherit self;
      };

      # Shared configuration for all hosts
      commonModules = [
        ./modules/nixos
        home-manager.nixosModules.home-manager
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            extraSpecialArgs = {
              inputs = inputs';
            };
            sharedModules = [
              inputs.sops-nix.homeManagerModules.sops
            ];
          };
        }
      ];

      # Define Colmena hive with all hosts and deployment settings
      colmenaHive = colmena.lib.makeHive {
        meta = {
          nixpkgs = import nixpkgs { system = "x86_64-linux"; };
          specialArgs = {
            inputs = inputs';
          };
        };

        hephaestus =
          { ... }:
          {
            imports = commonModules ++ [
              ./configurations/nixos/hephaestus/default.nix
              ./configurations/nixos/hephaestus/configuration.nix
            ];

            deployment = {
              allowLocalDeployment = true;
              targetHost = "localhost";
              targetUser = "gorschu";
              tags = [
                "workstation"
                "local"
              ];
              sshOptions = [
                "-i"
                "/home/gorschu/Downloads/general"
              ];
            };
          };

        hephaestus-vm =
          { ... }:
          {
            imports = commonModules ++ [
              ./configurations/nixos/hephaestus-vm/default.nix
            ];

            deployment = {
              targetHost = "hephaestus-vm";
              targetUser = "root";
              tags = [
                "vm"
                "test"
              ];
            };
          };
      };
    in
    flake-parts.lib.mkFlake { inherit inputs; } {
      # Import flake modules
      imports = [
        ./modules/flake/devshell.nix
        ./modules/flake/git-hooks.nix
        ./modules/flake/neovim.nix
        ./modules/flake/toplevel.nix
      ];

      # Define systems we support
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      # Expose Colmena hive
      flake = {
        inherit colmenaHive;

        # NixOS configurations - manually defined using same imports as Colmena
        nixosConfigurations = {
          hephaestus = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            specialArgs = {
              inputs = inputs';
            };
            modules = commonModules ++ [
              ./configurations/nixos/hephaestus/default.nix
              ./configurations/nixos/hephaestus/configuration.nix
            ];
          };

          hephaestus-vm = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            specialArgs = {
              inputs = inputs';
            };
            modules = commonModules ++ [
              ./configurations/nixos/hephaestus-vm/default.nix
            ];
          };
        };

        # Home-manager standalone configurations (for non-NixOS systems)
        homeConfigurations = {
          "gorschu@hephaestus" = home-manager.lib.homeManagerConfiguration {
            pkgs = nixpkgs.legacyPackages.x86_64-linux;
            extraSpecialArgs = {
              inputs = inputs';
            };
            modules = [
              inputs.sops-nix.homeManagerModules.sops
              ./modules/home
              ./configurations/home/gorschu.nix
            ];
          };
        };
        # Expose modules for reuse
        nixosModules.default = ./modules/nixos;
        homeModules.default = ./modules/home;
      };

    };
}
