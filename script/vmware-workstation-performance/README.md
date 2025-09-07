# VMware Workstation Performance on Windows 11

On Windows 11, **Hyper-V** and **Virtualization-Based Security (VBS/HVCI)** are often enabled by default on modern CPUs.  
This forces VMware Workstation (and VirtualBox) to run on top of the **Windows Hypervisor Platform (WHP)** instead of directly accessing VT-x/AMD-V.  

The result? Lower performance, reduced compatibility, and unexpected issues.  

These scripts let you **toggle Hyper-V on/off** and **validate** whether VMware is really running with **native hardware acceleration**.

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
- ✅ Run this **before installing or running VMware Workstation** for maximum performance

---

### 2. Enable-HyperV-For-Workstation.ps1
- Re-enables:
  - Hyper-V
  - Windows Hypervisor Platform (WHP)
  - Virtual Machine Platform (VMP)
  - Windows Sandbox
  - VBS / HVCI (Memory Integrity)
  - Credential Guard
- Configures Hyper-V to start again at boot
- ✅ Run this when you want to **restore Microsoft’s virtualization stack and security features**

---

### 3. Validate-Workstation-Native.ps1
- Validates your setup:
  - Checks if Hyper-V, WHP, VMP, and VBS are disabled  
  - Confirms boot config (`hypervisorlaunchtype`)  
  - Detects hypervisor presence (`systeminfo`)  
  - Auto-detects `vmrun.exe` (PATH, registry, Program Files)  
  - Lists currently running VMs  
  - Parses each VM’s `vmware.log` to see if it’s running:
    - ✅ `native (VT-x/AMD-V)` — full performance  
    - ⚠️ `via Hyper-V (WHP)` — slower, still trapped by Hyper-V  
    - ❓ `unknown` — log unclear, check manually  

---

## ⚡ Usage

1. Open **PowerShell as Administrator**.
2. If script execution is blocked, run once:
   ```powershell
   Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force
