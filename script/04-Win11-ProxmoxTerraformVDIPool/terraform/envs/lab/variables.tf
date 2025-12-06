variable "pm_api_url" {
  type        = string
  description = "Proxmox API URL, e.g. https://pve-01:8006/api2/json"
}

variable "pm_api_token_id" {
  type        = string
  description = "Proxmox API token ID, e.g. terraform@pve!tf-token"
}

variable "pm_api_token_secret" {
  type        = string
  description = "Proxmox API token secret"
  sensitive   = true
}

variable "pm_node" {
  type        = string
  description = "Proxmox node name"
}

variable "template_name" {
  type        = string
  description = "Name of the Windows 11 template VM (tpl-win-11-v2)"
}

variable "pool" {
  type        = string
  description = "Proxmox pool to attach the VMs to"
}

variable "vm_count" {
  type        = number
  description = "How many Win11 VMs to deploy"
  default     = 3
}

variable "vm_name_prefix" {
  type        = string
  description = "Prefix for VM names"
  default     = "GP-P-BID-W11-"
}

variable "vm_id_start" {
  type        = number
  description = "Starting VMID"
  default     = 300
}

variable "cores" {
  type        = number
  default     = 4
}

variable "memory_mb" {
  type        = number
  default     = 8192
}

variable "disk_storage" {
  type        = string
  default     = "local-lvm"
}

variable "disk_size_gb" {
  type        = number
  default     = 80
}

variable "ci_user" {
  type        = string
  default     = "Administrator"
}

variable "ci_password" {
  type        = string
  sensitive   = true
}

variable "ci_dns_server" {
  type        = string
  description = "DNS server IP (typically domain controller)"
}

variable "ci_search_domain" {
  type        = string
  description = "DNS search domain"
  default     = "lab.local"
}

variable "network_bridge" {
  type        = string
  default     = "vmbr0"
}

variable "ci_ipv4_cidr" {
  type        = string
  description = "VM network in CIDR format, e.g. 172.22.25.0/24"
}

variable "ci_gateway" {
  type        = string
  description = "Gateway IP address for VMs"
}

variable "ci_ip_host_offset" {
  type        = number
  description = "Starting host offset for first VM"
  default     = 20
}
