{
  # The NixOS HTML manual (nixos-help) and its options doc are a heavy build
  # we never use on these workstations. Disable globally. Man pages stay so
  # `man configuration.nix` etc. still work.
  documentation.nixos.enable = false;
}
