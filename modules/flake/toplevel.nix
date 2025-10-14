# Top-level flake configuration
_: {
  perSystem =
    { pkgs, ... }:
    {
      # For 'nix fmt'
      formatter = pkgs.nixfmt;
    };
}
