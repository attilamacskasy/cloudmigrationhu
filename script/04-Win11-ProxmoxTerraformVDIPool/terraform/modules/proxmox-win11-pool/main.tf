variable "pm_node" {
  type        = string
  description = "Proxmox node name where VMs will be created"
}

variable "template_name" {
  type        = string
  description = "Name of the Proxmox Windows 11 template VM to clone"
}

variable "pool" {
  type        = string
  description = "Proxmox pool name to attach VMs to"
}

variable "vm_count" {
  type        = number
  description = "How many VMs to create in the pool"
  default     = 1
}

variable "vm_name_prefix" {
  type        = string
  description = "Prefix for VM names, index will be appended"
}

variable "vm_id_start" {
  type        = number
  description = "First VMID to use; each VM will add +index"
}

variable "cores" {
  type        = number
  description = "vCPU cores per VM"
  default     = 4
}

variable "memory_mb" {
  type        = number
  description = "Memory per VM in MB"
  default     = 8192
}

variable "disk_storage" {
  type        = string
  description = "Proxmox storage name for the main disk"
}

variable "disk_size_gb" {
  type        = number
  description = "Disk size in GB"
  default     = 80
}

variable "ci_user" {
  type        = string
  description = "Cloud-Init user (Windows local Administrator account)"
}

variable "ci_password" {
  type        = string
  description = "Cloud-Init password for the user"
  sensitive   = true
}

variable "ci_dns_server" {
  type        = string
  description = "DNS server IP (typically your AD DNS)"
}

variable "ci_search_domain" {
  type        = string
  description = "DNS search domain (e.g. lab.local)"
}

variable "network_bridge" {
  type        = string
  description = "Proxmox bridge to connect VM NICs to"
}

variable "ci_ipv4_cidr" {
  type        = string
  description = "Network in CIDR format, e.g. 172.22.25.0/24"
}

variable "ci_gateway" {
  type        = string
  description = "Default gateway for the VMs"
}

variable "ci_ip_host_offset" {
  type        = number
  description = "Host offset for first VM; index is added for each next VM"
  default     = 20
}

variable "cloudinit_snippet" {
  type        = string
  description = "Optional cicustom snippet reference for additional Cloud-Init userdata (e.g. domain join parameters)"
  default     = ""
}

resource "proxmox_vm_qemu" "win11_pool" {
  count       = var.vm_count
  name        = format("%s%02d", var.vm_name_prefix, count.index + 1)
  target_node = var.pm_node
  pool        = var.pool

  # Base template clone
  clone      = var.template_name
  full_clone = true

  # VMID assignment (simple incremental scheme)
  vmid = var.vm_id_start + count.index

  # Hardware
  agent  = 1
  cores  = var.cores
  memory = var.memory_mb

  scsihw = "virtio-scsi-single"
  boot   = "order=scsi0"

  disk {
    slot    = "scsi0"
    size    = "${var.disk_size_gb}G"
    storage = var.disk_storage
    type    = "scsi"
  }

  network {
    id     = 0
    model  = "virtio"
    bridge = var.network_bridge
  }

  # Cloud-Init basic settings
  ciuser       = var.ci_user
  cipassword   = var.ci_password
  nameserver   = var.ci_dns_server
  searchdomain = var.ci_search_domain

  # IPv4 address per VM (static)
  # Terraform's cidrhost() picks an IP inside the ci_ipv4_cidr network
  ipconfig0 = "ip=${cidrhost(var.ci_ipv4_cidr, var.ci_ip_host_offset + count.index)}/24,gw=${var.ci_gateway}"

  # Optional: attach extra userdata snippet with domain join settings
  # Example value: "user=local:snippets/win11-domain-join-${count.index + 1}.yml"
  cicustom = var.cloudinit_snippet != "" ? var.cloudinit_snippet : null

  lifecycle {
    ignore_changes = [
      # Prevent Terraform from fighting with Proxmox on these
      network,
      disk,
    ]
  }
}

output "vm_names" {
  description = "Names of created Windows 11 VMs"
  value       = [for vm in proxmox_vm_qemu.win11_pool : vm.name]
}

output "vm_ids" {
  description = "VMIDs of created Windows 11 VMs"
  value       = [for vm in proxmox_vm_qemu.win11_pool : vm.vmid]
}
