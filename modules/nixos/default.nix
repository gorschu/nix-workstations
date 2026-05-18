# Core NixOS configuration
# Imports all module categories (core/networking/storage/gui/virt/gaming/flatpak)
# Control what's enabled via nixconfig.* options
{
  imports = [
    ./core
    ./networking
    ./storage
    ./gui
    ./virt
    ./gaming
    ./flatpak
  ];
}
