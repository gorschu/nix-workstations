{
  perSystem =
    { config, pkgs, ... }:
    {
      devShells.default = pkgs.mkShell {
        name = "nixos-unified-template-shell";
        meta.description = "Shell environment for modifying this Nix configuration";
        packages = with pkgs; [
          just
          nixd
          nixos-rebuild
          omnix
        ];

        # Install pre-commit hooks on shell entry
        shellHook = ''
          ${config.pre-commit.installationScript}
        '';
      };
    };
}
