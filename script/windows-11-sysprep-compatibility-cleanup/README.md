# Windows 11 Guest Customization Script for Proxmox

This folder contains `Win11-SysprepCleanup.ps1`, a PowerShell script that prepares a Windows 11 virtual machine to be used as a **Proxmox template** with **cloudbase-init** and **cloud-init**.

The script automates:
- Managing **cloudbase-init** services (disable while you customize; enable before templating).
- Ensuring **BitLocker** on `C:` is fully disabled so Sysprep can run.
- Removing **Sysprep-blocking AppX packages** (including language packs and bloatware).
- Optionally deep-scanning **user-only AppX packages** that often cause Sysprep errors.
- Generating a localized **`unattend.xml`** file for Windows 11 OOBE automation.
- Running **Sysprep** (`/generalize /oobe /shutdown`) and shutting down the VM.

The end result is a clean Windows 11 image that Proxmox can use as a template for fully automated guest customization.

---

## 1. High-Level Workflow

### Step 1 – Initial Setup (Before Installing Applications)

Run this from an elevated PowerShell window (Run as Administrator):

```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force

.\Win11-SysprepCleanup.ps1 -CloudbaseAction Disable
```

This **disables cloudbase-init services** so they do not interfere with:
- Application installations
- Windows updates
- Custom configuration scripts

### Step 2 – Customize the VM

With cloudbase-init disabled, perform all your customizations:
- Install applications (Office, browsers, utilities, agents, etc.).
- Apply Windows updates.
- Configure OS and application settings.
- Install any prerequisites you want baked into the template.

### Step 3 – Final Preparation (After All Installations Complete)

When you are ready to turn the VM into a template, run the script in **Enable + Cleanup + (optional) unattend + Sysprep** mode.

#### Recommended – Hungarian (hu-HU) template

```powershell
.\Win11-SysprepCleanup.ps1 -CloudbaseAction Enable -RunSysprep -UnattendLanguage hu-HU
```

#### Recommended – English (en-US) template

```powershell
.\Win11-SysprepCleanup.ps1 -CloudbaseAction Enable -RunSysprep -UnattendLanguage en-US
```

With `-RunSysprep`, the script does:
1. **Cloudbase-init management**
   - Re-enables `cloudbase-init` and `cloudbase-init-unattend`.
   - Sets them to Automatic so they run on first boot of cloned VMs.
2. **BitLocker cleanup**
   - Detects BitLocker status on `C:` using `Get-BitLockerVolume` or `manage-bde`.
   - Disables BitLocker if it is enabled and waits until the drive is fully decrypted.
3. **AppX package cleanup**
   - Removes known Sysprep-blocking AppX packages for all users.
   - Removes provisioned packages so they do not reinstall for new user profiles.
4. **Optional deep scan (`-ScanUserPackages`)**
   - Finds AppX packages installed per-user that are not provisioned for all users.
   - Attempts to remove these user-only packages (a common source of Sysprep errors).
5. **Unattend.xml generation (`-UnattendLanguage`)**
   - Creates `C:\Windows\System32\Sysprep\unattend.xml` with your chosen language.
   - Configures language, keyboard, timezone, OOBE behavior, and a local admin account.
6. **Sysprep execution**
   - If `unattend.xml` exists and a language was requested:
     ```text
     Sysprep.exe /generalize /oobe /shutdown /unattend:C:\Windows\System32\Sysprep\unattend.xml
     ```
   - Otherwise:
     ```text
     Sysprep.exe /generalize /oobe /shutdown
     ```

The VM will **shut down automatically** when Sysprep completes.

### Step 4 – Convert to a Proxmox Template

After the VM shuts down:
1. **Do not boot it again.**
2. In the Proxmox UI, convert the VM to a **template**.
3. Use this template to deploy Windows 11 guests with **cloud-init** for customization (hostname, network, users, etc.).

---

## 2. Script Parameters

The script defines the following parameters:

```powershell
param(
    [Parameter(Mandatory=$false)]
    [ValidateSet('Check', 'Disable', 'Enable')]
    [string]$CloudbaseAction = 'Disable',
    
    [switch]$RunSysprep,

    [switch]$ScanUserPackages,

    [ValidateSet('en-US', 'hu-HU')]
    [string]$UnattendLanguage
)
```

### `-CloudbaseAction`
- `Check`   – Show current status of cloudbase-init services.
- `Disable` – Stop and disable cloudbase-init services.
- `Enable`  – Enable cloudbase-init services and set them to Automatic.

### `-RunSysprep`
- When present, runs Sysprep after cleanup (`/generalize /oobe /shutdown`).
- If `-UnattendLanguage` is also provided and `unattend.xml` exists, Sysprep runs with `/unattend`.

### `-UnattendLanguage`
- Supported values:
  - `en-US` – English (United States), time zone set to `UTC`.
  - `hu-HU` – Hungarian, time zone set to `Central Europe Standard Time`.
- When provided, generates `C:\Windows\System32\Sysprep\unattend.xml` that:
  - Skips all OOBE wizard screens (language, EULA, privacy, account setup).
  - Creates local admin user `localuser` with password `P@ssw0rd!`.
  - Sets keyboard layout, system locale, UI language, and user locale.
  - Sets timezone based on the chosen language.
  - Sets `SkipRearm=1` in the `generalize` pass so you can rebuild images multiple times.

### `-ScanUserPackages`
- Optional deep cleanup.
- Scans for **AppX packages installed per-user** that are **not** provisioned for all users.
- Attempts to remove them for all users/current user.
- Helps avoid stubborn Sysprep failures caused by leftover user apps.

---

## 3. How unattend.xml Helps Proxmox Deployments

When `-UnattendLanguage` is used, the script writes a full unattended setup file to:

> `C:\Windows\System32\Sysprep\unattend.xml`

Key behaviors:

- **Language & region**
  - Sets `InputLocale`, `SystemLocale`, `UILanguage`, `UILanguageFallback`, and `UserLocale` to the chosen language.
  - Sets `TimeZone` to `Central Europe Standard Time` for `hu-HU` or `UTC` for `en-US`.

- **OOBE skipping**
  - `HideEULAPage`, `HideOEMRegistrationScreen`, `HideOnlineAccountScreens`, `HideWirelessSetupInOOBE`.
  - `SkipUserOOBE = true`, `SkipMachineOOBE = true`.
  - This removes all OOBE screens, so the VM boots directly to the logon screen.

- **Local administrator account**
  - Creates `localuser` in the local `Administrators` group with password `P@ssw0rd!`.
  - Useful for first login/testing; you should change or disable this account in production.

- **No ComputerName set**
  - The unattend file **does not** set `ComputerName`. Proxmox + cloudbase-init + cloud-init will set hostname based on VM metadata.

Together, this means a Proxmox clone from the template:
- Boots without OOBE.
- Has a known local admin.
- Immediately runs cloudbase-init, which reads cloud-init configuration from Proxmox and applies hostname, network, users, and scripts.

---

## 4. Example Commands

### Check cloudbase-init status

```powershell
.\Win11-SysprepCleanup.ps1 -CloudbaseAction Check
```

### Disable cloudbase-init before customizing

```powershell
.\Win11-SysprepCleanup.ps1 -CloudbaseAction Disable
```

### Final cleanup + unattend.xml + Sysprep (Hungarian)

```powershell
.\Win11-SysprepCleanup.ps1 -CloudbaseAction Enable -RunSysprep -UnattendLanguage hu-HU
```

### Final cleanup + unattend.xml + Sysprep (English, US)

```powershell
.\Win11-SysprepCleanup.ps1 -CloudbaseAction Enable -RunSysprep -UnattendLanguage en-US
```

### Generate unattend.xml only (review/edit before Sysprep)

```powershell
.\Win11-SysprepCleanup.ps1 -CloudbaseAction Enable -UnattendLanguage hu-HU
```

Then run Sysprep manually if desired:

```powershell
C:\Windows\System32\Sysprep\Sysprep.exe /generalize /oobe /shutdown /unattend:C:\Windows\System32\Sysprep\unattend.xml
```

### Deep user-only AppX cleanup (more thorough, slower)

```powershell
.\Win11-SysprepCleanup.ps1 -CloudbaseAction Enable -ScanUserPackages -RunSysprep -UnattendLanguage hu-HU
```

---

## 5. How This Assists Windows 11 Guest Customization in Proxmox

This script prepares the **Windows side** of the automation, so that:

- The OS is **generalized** with Sysprep and free of common blockers.
- OOBE is **completely skipped** using `unattend.xml`.
- A local admin is available for manual access if needed.
- **cloudbase-init** is correctly enabled and will start on first boot.

Proxmox then handles the **cloud-init side**:

- You set hostname, IP/DNS, users, SSH keys, and scripts in the Proxmox UI.
- On first boot of each cloned VM:
  - Windows 11 skips OOBE and logs into a ready state.
  - cloudbase-init reads cloud-init metadata and applies your settings.

This combination gives you **Linux-like cloud-init behavior for Windows 11** in Proxmox with minimal manual steps.

---

## 6. Important Notes

- Always run the script in an elevated PowerShell session (Run as Administrator).
- If execution policy blocks the script, use:
  ```powershell
  Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
  ```
- After Sysprep shuts the VM down, **do not boot it again**. Convert it directly to a template.
- `localuser` / `P@ssw0rd!` is intended as a lab default. Change or disable this account for production.
- For Sysprep problems, check:
  ```
  C:\Windows\System32\Sysprep\Panther\setuperr.log
  ```

---

**Location:**
- Script: `Win11-SysprepCleanup.ps1`
- This README: `README.md`

Use them together to build robust Windows 11 templates for Proxmox.
