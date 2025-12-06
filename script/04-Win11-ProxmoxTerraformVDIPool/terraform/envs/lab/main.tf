terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "3.0.1-rc8"
    }
  }
}

provider "proxmox" {
  pm_api_url          = var.pm_api_url
  pm_api_token_id     = var.pm_api_token_id
  pm_api_token_secret = var.pm_api_token_secret
  pm_tls_insecure     = true
}

module "win11_pool" {
  source = "../../modules/proxmox-win11-pool"

  pm_node          = var.pm_node
  template_name    = var.template_name
  pool             = var.pool
  vm_count         = var.vm_count
  vm_name_prefix   = var.vm_name_prefix
  vm_id_start      = var.vm_id_start
  cores            = var.cores
  memory_mb        = var.memory_mb
  disk_storage     = var.disk_storage
  disk_size_gb     = var.disk_size_gb
  ci_user          = var.ci_user
  ci_password      = var.ci_password
  ci_dns_server    = var.ci_dns_server
  ci_search_domain = var.ci_search_domain
  network_bridge   = var.network_bridge
  ci_ipv4_cidr     = var.ci_ipv4_cidr
  ci_gateway       = var.ci_gateway
  ci_ip_host_offset = var.ci_ip_host_offset

  # If you later create a user-data snippet for domain join, set it here:
  # cloudinit_snippet = "user=local:snippets/win11-domain-join.yml"
}
