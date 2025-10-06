{ inputs, ... }:
{
  imports = [
    inputs.git-hooks.flakeModule
  ];

  perSystem = {
    # Configure git-hooks (pre-commit)
    pre-commit.settings.hooks = {
      # Nix formatting with official nixfmt
      nixfmt-rfc-style.enable = true;

      # Remove unused Nix code
      deadnix.enable = true;

      # Check flake inputs
      flake-checker.enable = true;

      # Nix linter
      statix.enable = true;

      # Detect secrets in code
      trufflehog.enable = true;

      # Ensure all secrets are encrypted with SOPS
      pre-commit-hook-ensure-sops.enable = true;
    };
  };
}
