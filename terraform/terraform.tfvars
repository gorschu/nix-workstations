vm_name      = "nixos-test"
memory_mb    = 12288
vcpus        = 8
disk_size_gb = 100

# OVMF firmware path — distro-specific:
#   Arch Linux: /usr/share/edk2/x64/OVMF_CODE.4m.fd
#   NixOS:      /run/libvirt/nix-helpers/OVMF_CODE.fd
#   Fedora:     /usr/share/edk2/ovmf/OVMF_CODE.fd
#   Ubuntu:     /usr/share/OVMF/OVMF_CODE.fd
ovmf_firmware = "/usr/share/edk2/x64/OVMF_CODE.4m.fd"
