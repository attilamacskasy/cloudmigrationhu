# Cloudbase-Init Windows Domain Join – Full Architecture

> **Goal**: Build a *repeatable*, “cloud-style” way to deploy Windows 11 VMs on Proxmox that:
>
> - boot from a **sysprepped golden image**
> - receive hostname, IP and credentials via **Proxmox cloud-init**
> - **join an Active Directory domain automatically** on first boot
> - can be mass-provisioned using **Terraform**

This folder contains the concept, reference configs and example scripts that tie all of this together.

---

## 1. High-Level Architecture

We use three main building blocks:

1. **Proxmox + Cloud-Init**
   - Proxmox provides a cloud-init disk (ConfigDrive v2).
   - It holds metadata such as hostname, IP config, initial username/password and optional custom data.

2. **Windows 11 Golden Image with Cloudbase-Init**
   - A manually prepared Windows 11 VM:
     - Optimized and cleaned up.
     - Sysprepped with an `unattend.xml` that skips most OOBE questions.
     - Has **Cloudbase-Init** installed and configured.
   - Cloudbase-Init reads Proxmox’s metadata and:
     - sets hostname
     - configures networking
     - runs **local PowerShell scripts** on first boot

3. **Terraform (Proxmox Provider)**
   - Terraform clones the golden template into many VMs.
   - For each VM it sets:
     - VM name / resources
     - Cloud-init network data (static or DHCP)
     - Cloud-init username/password (used for initial local or domain join account)
     - Optional extra metadata (for domain join OU, etc., if desired later)

### Life-of-a-VM

1. `terraform apply`
   - Proxmox clones the Windows 11 template into a new VM.
   - Proxmox generates a cloud-init disk for that VM with the given hostname/IP/creds.

2. First boot
   - Cloudbase-Init reads metadata from the cloud-init disk.
   - It sets hostname, IP and the Administrator (or template user) password.
   - It executes local scripts under `C:\Program Files\Cloudbase Solutions\Cloudbase-Init\LocalScripts\`.

3. Domain join script
   - A PowerShell script (`01-domain-join.ps1`) runs once.
   - Uses domain join credentials (passed via cloud-init or baked in for lab use).
   - Calls `Add-Computer` to join the AD domain and optionally move the computer into a specific OU.
   - Reboots if needed.

Result: a **domain-joined, fully configured** Windows 11 VM with no manual clicks.

---

## 2. Windows 11 Golden Image

This image is prepared once and then reused for all clones.

### 2.1. Base OS & Apps

On a clean VM (no template yet):

1. Install Windows 11 (Pro, Enterprise or Education) on Proxmox.
2. Install drivers / guest tools:
   - VirtIO drivers if needed.
   - Optional: guest tools for clipboard, etc.
3. Install common apps *before* Sysprep:
   - Microsoft 365 Apps (Office) with your preferred channel / licensing.
   - PDF reader (e.g., Acrobat Reader or other).
   - Browser(s).
   - VC++ Redistributables, .NET runtimes, OneDrive, Teams machine-wide, etc.
4. Configure Windows update, time, language and region as you prefer for the lab.

The idea is: **everything that should be on every VM goes into the golden image**.

### 2.2. Cloudbase-Init Installation

Install Cloudbase-Init using the official MSI inside the VM.

Typical installer choices:

- Username: `Administrator` (we will *not* use this to create a new user; we will override behavior in config).
- Local groups: `Administrators`
- Run service as: **LocalSystem**
- Do **not** let the installer run Sysprep for you.

After install, check `C:\Program Files\Cloudbase Solutions\Cloudbase-Init\conf\` for:

- `cloudbase-init.conf`
- `cloudbase-init-unattend.conf`
- `Unattend.xml` (the OEM unattend file used when Cloudbase-Init runs sysprep; we keep our own Sysprep flow, but it’s good reference)
