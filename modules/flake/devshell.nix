_: {
  perSystem =
    { pkgs, ... }:
    {
      devShells.default = pkgs.mkShell {
        name = "nix-workstations-shell";
        meta.description = "Shell environment for modifying this Nix configuration";
        packages = with pkgs; [
          age
          just
          mkpasswd
          nixd
          nixos-rebuild
          omnix
          sops
          ssh-to-age
          opentofu
        ];
      };
    };
}
