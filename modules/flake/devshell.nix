{ inputs, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      devShells.default = pkgs.mkShell {
        name = "nix-workstations-shell";
        meta.description = "Shell environment for modifying this Nix configuration";
        packages = with pkgs; [
          just
          nixd
          nixos-rebuild
          omnix
          inputs.colmena.packages.${pkgs.system}.colmena
          sops
        ];
      };
    };
}
