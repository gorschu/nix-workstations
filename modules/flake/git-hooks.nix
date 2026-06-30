{ inputs, ... }:
{
  imports = [
    inputs.git-hooks.flakeModule
  ];

  perSystem =
    { pkgs, ... }:
    {
      # Configure git-hooks (pre-commit)
      pre-commit.settings.hooks = {
        nixfmt.enable = true;

        # Remove unused Nix code
        deadnix.enable = true;

        # Check flake inputs
        flake-checker.enable = true;

        # Nix linter - disabled due to false positives with flake-parts
        # (W20 repeated keys warning is expected in flake-parts structure)
        # statix.enable = true;

        # Detect secrets in code
        trufflehog.enable = true;

        # Lint commit messages (requires conventional commits)
        # Configuration in .gitlint file
        gitlint.enable = true;

        # Ensure all files in secrets/ are SOPS-encrypted
        check-secrets-encrypted = {
          enable = true;
          name = "check-secrets-encrypted";
          description = "Ensure all files in secrets/ are SOPS-encrypted";
          entry = "${pkgs.writeShellScript "check-secrets-encrypted" ''
            set -e
            exit_code=0

            # Process each file passed by pre-commit
            for file in "$@"; do
              # Skip example files
              if [[ "$file" == *.example ]]; then
                continue
              fi

              # Check if file is SOPS-encrypted using sops filestatus
              status=$(${pkgs.sops}/bin/sops filestatus "$file" 2>/dev/null || echo '{"encrypted":false}')
              encrypted=$(echo "$status" | ${pkgs.jq}/bin/jq -r '.encrypted')

              if [ "$encrypted" != "true" ]; then
                echo "ERROR: Unencrypted secret file detected: $file"
                echo "Please encrypt with: sops -e -i \"$file\""
                exit_code=1
              fi
            done

            exit $exit_code
          ''}";
          files = "^secrets/.*";
          excludes = [ "\\.example$" ];
        };

        # Prevent unencrypted SSH host keys from being committed
        check-ssh-host-keys = {
          enable = true;
          name = "check-ssh-host-keys";
          description = "Ensure SSH host keys are SOPS-encrypted";
          entry = "${pkgs.writeShellScript "check-ssh-host-keys" ''
            set -e
            exit_code=0

            # Process each file passed by pre-commit
            for key in "$@"; do
              # Check if file is SOPS-encrypted using sops filestatus
              status=$(${pkgs.sops}/bin/sops filestatus "$key" 2>/dev/null || echo '{"encrypted":false}')
              encrypted=$(echo "$status" | ${pkgs.jq}/bin/jq -r '.encrypted')

              if [ "$encrypted" != "true" ]; then
                echo "ERROR: Unencrypted SSH host key detected: $key"
                echo "Please encrypt with: sops -e -i \"$key\""
                exit_code=1
              fi
            done

            exit $exit_code
          ''}";
          files = "^extra-files/.*/(?:persist/)?etc/ssh/ssh_host_.*_key$";
          excludes = [ "\\.pub$" ];
        };
      };
    };
}
