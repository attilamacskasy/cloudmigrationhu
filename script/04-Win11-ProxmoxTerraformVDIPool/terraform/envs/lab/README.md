# Terraform lab environment – Proxmox Windows 11 pool

This directory is an example environment that uses the `proxmox-win11-pool` module
to deploy multiple Windows 11 VMs from your golden template.

## Files

- `main.tf` – wires the Proxmox provider and the module
- `variables.tf` – input variables for this environment
- `terraform.tfvars.example` – example values you can copy to `terraform.tfvars`

## Usage

```bash
cd terraform/envs/lab
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars with your Proxmox URL, token, network, etc.

terraform init
terraform plan
terraform apply
```
