# Hyper-V Toggle Scripts for VMware Workstation

These scripts help you **switch between VMware Workstation** (with full native hardware access) and **Microsoft Hyper-V / VBS security features** on Windows 11.

On modern CPUs, Windows 11 enables **Hyper-V**, **Virtualization-Based Security (VBS)**, and **Hypervisor-Protected Code Integrity (HVCI)** by default.  
This causes VMware Workstation (and sometimes VirtualBox) to run on top of the **Windows Hypervisor Platform**, which reduces performance and compatibility.

These scripts let you toggle between the two worlds:

- **Disable-HyperV-For-Workstation.ps1** → Best performance for VMware Workstation  
- **Enable-HyperV-For-Workstation.ps1** → Restore Hyper-V and Windows security features  

---

## 📌 Scripts

### 1. Disable-HyperV-For-Workstation.ps1
- Disables:
  - Hyper-V
  - Windows Hypervisor Platform (WHP)
  - Virtual Machine Platform (VMP)
  - Windows Sandbox
  - VBS / HVCI (Memory Integrity)
  - Credential Guard
- Prevents Hyper-V from starting at boot
- Use **before installing or running VMware Workstation** for maximum performance

### 2. Enable-HyperV-For-Workstation.ps1
- Re-enables:
  - Hyper-V
  - Windows Hypervisor Platform (WHP)
  - Virtual Machine Platform (VMP)
  - Windows Sandbox
  - VBS / HVCI (Memory Integrity)
  - Credential Guard
- Configures Hyper-V to start again at boot
- Use when you want to **restore Microsoft’s virtualization stack and security features**

---

## ⚡ Usage

1. Open **PowerShell as Administrator**.
2. By default, Windows may block script execution. If so, run this once:
   ```powershell
   Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force
