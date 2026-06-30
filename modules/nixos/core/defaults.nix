{
  # NixOS enables nano by default through programs.nano. We use Neovim via Home
  # Manager and do not want nano in the system closure.
  programs.nano.enable = false;
}
