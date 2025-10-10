# Colmena deployment configuration
# Exports colmenaHive for parallel, tag-based deployment
# Reuses nixos-unified configurations
{ inputs, ... }:
{
  flake = {
    # Export colmenaHive for Colmena deployment using colmena.lib.makeHive
    colmenaHive = inputs.colmena.lib.makeHive {
      meta = {
        # Global nixpkgs for all nodes
        nixpkgs = import inputs.nixpkgs {
          system = "x86_64-linux";
        };

        # Make all flake inputs available to nodes
        specialArgs = {
          inherit inputs;
          flake = inputs.self;
        };
      };

      # Individual host configurations
      # Reuse the nixosConfigurations from nixos-unified autowiring
      hephaestus =
        { ... }:
        {
          # Import the full nixosConfiguration which includes home-manager
          imports = [
            inputs.self.nixosConfigurations.hephaestus.config.system.build.toplevel.outPath
          ];

          # Colmena deployment settings
          deployment = {
            # Deploy to localhost (current machine)
            targetHost = "localhost";
            targetUser = "root";
            # For remote deployment, use:
            # targetHost = "hephaestus.example.com";
            # targetPort = 22;
            tags = [
              "workstation"
              "local"
            ];
          };
        };

      hephaestus-vm =
        { ... }:
        {
          imports = [
            inputs.self.nixosConfigurations.hephaestus-vm.config.system.build.toplevel.outPath
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
  };
}
