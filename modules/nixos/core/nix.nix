_: {
  # Nix daemon and store configuration
  nix.settings = {
    # Enable flakes and nix command
    experimental-features = [
      "nix-command"
      "flakes"
    ];

    # Binary caches for faster builds
    substituters = [
      "https://cache.nixos.org"
      "https://hyprland.cachix.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
    ];

    # Optimize store automatically
    auto-optimise-store = true;
  };

  # Use nh (nix-helper) for better NixOS/home-manager management
  programs.nh = {
    enable = true;
    # Automatic garbage collection via nh clean
    clean = {
      enable = true;
      # Keep last 10 generations OR anything from last 30 days (whichever keeps more)
      extraArgs = "--keep 10 --keep-since 30d";
    };
  };

  # Limit boot menu entries to last 10
  boot.loader.systemd-boot.configurationLimit = 10;
}
