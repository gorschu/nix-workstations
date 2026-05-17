terraform {
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "~> 0.9"
    }
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}

variable "vm_name" {
  description = "Name of the VM"
  type        = string
}

variable "memory_mb" {
  description = "Memory in MiB"
  type        = number
}

variable "vcpus" {
  description = "Number of virtual CPUs"
  type        = number
}

variable "disk_size_gb" {
  description = "Disk size in GB"
  type        = number
}

variable "ovmf_firmware" {
  description = "Path to OVMF firmware on the libvirt host. Arch: /usr/share/edk2/x64/OVMF_CODE.4m.fd, NixOS: /run/libvirt/nix-helpers/OVMF_CODE.fd"
  type        = string
}

# Download nixos-images installer ISO (shared across VMs, uses default pool)
resource "libvirt_volume" "nixos_installer_iso" {
  name = "nixos-installer-x86_64-linux.iso"
  pool = "default"

  create = {
    content = {
      url = "https://github.com/nix-community/nixos-images/releases/download/nixos-unstable/nixos-installer-x86_64-linux.iso"
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}

# VM disk
resource "libvirt_volume" "vm_disk" {
  name     = "${var.vm_name}.qcow2"
  pool     = "default"
  capacity = var.disk_size_gb * 1024 * 1024 * 1024

  target = {
    format = {
      type = "qcow2"
    }
  }
}

# Define the VM
resource "libvirt_domain" "nixos_vm" {
  name        = var.vm_name
  memory      = var.memory_mb
  memory_unit = "MiB"
  vcpu        = var.vcpus
  type        = "kvm"

  cpu = {
    mode = "host-passthrough"
  }

  os = {
    type         = "hvm"
    type_arch    = "x86_64"
    type_machine = "q35"
    loader          = var.ovmf_firmware
    loader_type     = "pflash"
    loader_readonly = "yes"
  }

  features = {
    acpi = true
  }

  devices = {
    disks = [
      {
        source = {
          volume = {
            pool   = libvirt_volume.vm_disk.pool
            volume = libvirt_volume.vm_disk.name
          }
        }
        target = {
          dev = "vda"
          bus = "virtio"
        }
        driver = {
          type = "qcow2"
        }
      },
      {
        device = "cdrom"
        source = {
          volume = {
            pool   = libvirt_volume.nixos_installer_iso.pool
            volume = libvirt_volume.nixos_installer_iso.name
          }
        }
        target = {
          dev = "sdb"
          bus = "sata"
        }
      }
    ]

    interfaces = [
      {
        type  = "network"
        model = { type = "virtio" }
        source = {
          network = {
            network = "default"
          }
        }
      }
    ]

    consoles = [
      {
        type = "pty"
        target = {
          type = "serial"
          port = 0
        }
      }
    ]

    graphics = [
      {
        vnc = {
          auto_port = true
          listen    = "0.0.0.0"
        }
      }
    ]
  }

  running = true
}

# Query VM IP after boot (run `just vm-info` once the VM has a DHCP lease)
data "libvirt_domain_interface_addresses" "nixos_vm" {
  domain = libvirt_domain.nixos_vm.name
  source = "lease"
}

output "vm_name" {
  value = libvirt_domain.nixos_vm.name
}

output "vm_ip" {
  description = "IP address of the VM (once DHCP assigns it)"
  value = (
    length(data.libvirt_domain_interface_addresses.nixos_vm.interfaces) > 0 &&
    length(data.libvirt_domain_interface_addresses.nixos_vm.interfaces[0].addrs) > 0
    ? data.libvirt_domain_interface_addresses.nixos_vm.interfaces[0].addrs[0].addr
    : "IP not yet assigned"
  )
}
