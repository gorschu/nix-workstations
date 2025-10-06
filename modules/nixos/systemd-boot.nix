{ lib, ... }:
{
  # Use systemd-boot as the default bootloader
  boot.loader = {
    systemd-boot = {
      enable = lib.mkDefault true;
      consoleMode = lib.mkDefault "max";
    };
    efi.canTouchEfiVariables = lib.mkDefault true;
  };
}
