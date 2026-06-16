{ pkgs, config, ... }:
{
  # Print a human-readable package diff (added/removed/version changes) on every
  # nixos-rebuild switch / `just deploy`, comparing the running system to the one
  # being activated. Runs on the target during switch-to-configuration, so the
  # output streams back during remote deploys too.
  system.activationScripts.generationDiff = {
    supportsDryActivation = true;
    text = ''
      if [[ -e /run/current-system ]]; then
        echo "--- system changes ---"
        ${pkgs.nvd}/bin/nvd --nix-bin-dir=${config.nix.package}/bin diff /run/current-system "$systemConfig" || true
      fi
    '';
  };
}
