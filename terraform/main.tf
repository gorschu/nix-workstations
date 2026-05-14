terraform {
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "~> 0.8"
    }
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}

variable "vm_name" {
  description = "Name of the VM"
  type        = string
  default     = "nixos-test"
}

variable "memory_mb" {
  description = "Memory in MB"
  type        = number
  default     = 8192
}

variable "vcpus" {
  description = "Number of virtual CPUs"
  type        = number
  default     = 8
}

variable "disk_size_gb" {
  description = "Disk size in GB"
  type        = number
  default     = 100
}

variable "ovmf_firmware" {
  description = "Path to OVMF firmware on the libvirt host (NixOS: /run/libvirt/nix-helpers/OVMF_CODE.fd)"
  type        = string
  default     = "/run/libvirt/nix-helpers/OVMF_CODE.fd"
}

# Download nixos-images installer ISO (shared across VMs, uses default images pool)
resource "libvirt_volume" "nixos_installer_iso" {
  name   = "nixos-installer-x86_64-linux.iso"
  pool   = "images"
  source = "https://github.com/nix-community/nixos-images/releases/download/nixos-unstable/nixos-installer-x86_64-linux.iso"

  lifecycle {
    prevent_destroy = true
  }
}

# VM disk (uses default images pool)
resource "libvirt_volume" "vm_disk" {
  name   = "${var.vm_name}.qcow2"
  pool   = "images"
  format = "qcow2"
  size   = var.disk_size_gb * 1024 * 1024 * 1024
}

# Define the VM
resource "libvirt_domain" "nixos_vm" {
  name   = var.vm_name
  memory = var.memory_mb
  vcpu   = var.vcpus

  firmware = var.ovmf_firmware

  cpu {
    mode = "host-passthrough"
  }

  disk {
    volume_id = libvirt_volume.vm_disk.id
  }

  disk {
    file = libvirt_volume.nixos_installer_iso.id
  }

  network_interface {
    network_name   = "default"
    wait_for_lease = true
  }

  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  graphics {
    type        = "vnc"
    listen_type = "address"
    autoport    = true
  }
}

output "vm_name" {
  value = libvirt_domain.nixos_vm.name
}

output "vm_ip" {
  value       = try(libvirt_domain.nixos_vm.network_interface[0].addresses[0], "IP not yet assigned")
  description = "IP address of the VM (once DHCP assigns it)"
}
