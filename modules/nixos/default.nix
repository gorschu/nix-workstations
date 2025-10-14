# Core NixOS configuration
# Imports all module categories (core/networking/storage/gui/virt)
# Control what's enabled via nixconfig.* options
{
  imports = [
    ./core
    ./networking
    ./storage
    ./gui
    ./virt
  ];
}
