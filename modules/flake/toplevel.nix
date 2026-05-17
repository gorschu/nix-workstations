# Top-level flake configuration
_: {
  perSystem =
    { pkgs, ... }:
    {
      # For 'nix fmt' — nixfmt-tree wraps treefmt+nixfmt to handle directory traversal
      formatter = pkgs.nixfmt-tree;
    };
}
