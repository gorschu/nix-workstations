# Core NixOS configuration
# Imports all module categories (core/storage/gui/virt)
# Control what's enabled via nixconfig.* options
{
  imports = [
    ./core
    ./storage
    ./gui
    ./virt
  ];
}
