# Windows 11 Sysprep Troubleshooting Guide

## Common Sysprep Error: Language Experience Packs

### The Problem
**Error Message:**
```
SYSPREP Package Microsoft.LanguageExperiencePackhu-HU_Z6100.131.226.0
_neutral__8wekyb3d8bbwe was installed for a user, but not provisioned 
for all users. This package will not function properly in the sysprep image.
```

### Why This Happens
When you install a language pack or language experience pack for a specific user (e.g., Hungarian language pack), Windows installs it only for that user account. However, **Sysprep requires all AppX packages to be either:**
1. Installed for ALL users, OR
2. Provisioned for all users (included in the Windows image)

If a package is installed for only one user, Sysprep will fail during the generalization phase.

### The Solution
The updated `Win11-SysprepCleanup.ps1` script now:

#### 1. **Scans for User-Only Packages**
```powershell
Find-UserOnlyAppxPackages
```
This function identifies ALL packages installed for users but not provisioned for all users.

#### 2. **Removes Language Experience Packs**
The script specifically targets:
- `Microsoft.LanguageExperiencePack*` (all language packs)
- Other common Sysprep blockers

#### 3. **Performs Final Verification**
After cleanup, the script re-scans to ensure no user-only packages remain.

## Complete Workflow for Sysprep Success

### Stage 1: Disable Cloudbase-Init (Before Customization)
```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
.\Win11-SysprepCleanup.ps1 -CloudbaseAction Disable
```

**What happens:**
- Cloudbase-init services are stopped and disabled
- You can now safely install applications

### Stage 2: Customize Your System
Install everything you need:
- ✅ Applications (Office, browsers, utilities)
- ✅ Windows Updates
- ✅ Language packs (if needed)
- ✅ Drivers
- ✅ Configuration changes

### Stage 3: Final Cleanup and Sysprep
```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
.\Win11-SysprepCleanup.ps1 -CloudbaseAction Enable -RunSysprep
```

**What happens:**
1. ✅ Re-enables cloudbase-init services (required for Proxmox cloud-init)
2. ✅ Disables BitLocker on C: drive
3. ✅ **Scans for user-only AppX packages** (the critical step!)
4. ✅ **Removes language experience packs** and other blockers
5. ✅ Removes known Sysprep-blocking AppX packages
6. ✅ **Verifies no user-only packages remain**
7. ✅ Runs Sysprep /generalize /oobe /shutdown
8. ✅ System shuts down ready for template conversion

### Stage 4: Create Proxmox Template
After the VM shuts down:
- **DO NOT boot the VM again!**
- Convert to Proxmox template
- Deploy new VMs using cloud-init

## Manual Troubleshooting

### If Sysprep Still Fails

#### 1. Check the Sysprep Logs
```powershell
notepad C:\Windows\System32\Sysprep\Panther\setuperr.log
```

Look for lines containing:
- `Failed while validating Sysprep session`
- `Package Microsoft.LanguageExperiencePack`
- `was installed for a user, but not provisioned for all users`

#### 2. List All User-Only Packages
```powershell
$all = Get-AppxPackage -AllUsers
$prov = Get-AppxProvisionedPackage -Online
foreach ($pkg in $all) {
    $isProvisioned = $prov | Where-Object { $_.DisplayName -eq $pkg.Name }
    if (-not $isProvisioned) {
        Write-Host "$($pkg.Name) - USER ONLY (Sysprep blocker!)" -ForegroundColor Red
    }
}
```

#### 3. Manually Remove a Specific Package
```powershell
# Replace with the actual package name from the error log
Get-AppxPackage -Name "Microsoft.LanguageExperiencePackhu-HU*" -AllUsers | Remove-AppxPackage -AllUsers
```

#### 4. Remove ALL Language Experience Packs
```powershell
Get-AppxPackage -Name "Microsoft.LanguageExperiencePack*" -AllUsers | Remove-AppxPackage -AllUsers
```

#### 5. Check for Remaining Issues
```powershell
.\Win11-SysprepCleanup.ps1 -CloudbaseAction Check
```

## Common Sysprep Blockers

| Package Pattern | Description | Why It Blocks Sysprep |
|----------------|-------------|----------------------|
| `Microsoft.LanguageExperiencePack*` | Language/region packs | Often installed per-user |
| `Microsoft.Xbox*` | Xbox gaming apps | May have per-user installations |
| `Microsoft.GetHelp*` | Windows Help | User-specific installations |
| `Microsoft.YourPhone*` | Phone Link app | User account linking |
| `Microsoft.People*` | Contacts app | User-specific data |

## Best Practices

### ✅ DO
- Run the cleanup script **before** every Sysprep attempt
- **Reboot** after cleanup and before Sysprep
- Verify no user-only packages remain
- Check Sysprep logs if it fails
- Use cloud-init for post-deployment customization

### ❌ DON'T
- Skip the AppX package cleanup
- Boot a VM after Sysprep completes
- Install language packs during Windows setup (add them via cloud-init later)
- Ignore warnings about user-only packages

## Quick Reference Commands

### Check for Sysprep Blockers
```powershell
.\Win11-SysprepCleanup.ps1 -CloudbaseAction Check
```

### Just Remove AppX Packages (No Sysprep)
```powershell
.\Win11-SysprepCleanup.ps1 -CloudbaseAction Enable
```

### Full Cleanup + Sysprep
```powershell
.\Win11-SysprepCleanup.ps1 -CloudbaseAction Enable -RunSysprep
```

### Manual Sysprep (After Cleanup)
```powershell
C:\Windows\System32\Sysprep\Sysprep.exe /generalize /oobe /shutdown
```

## Additional Resources

- **Sysprep Error Logs:** `C:\Windows\System32\Sysprep\Panther\`
  - `setuperr.log` - Errors
  - `setupact.log` - Actions taken
  
- **AppX Package Management:**
  ```powershell
  Get-AppxPackage -AllUsers  # List all packages
  Get-AppxProvisionedPackage -Online  # List provisioned packages
  ```

- **Windows Event Viewer:**
  - Applications and Services Logs → Microsoft → Windows → AppXDeployment-Server

## Support

If Sysprep continues to fail after running the updated script:
1. Review the script output for any packages that failed to remove
2. Check `setuperr.log` for specific package names
3. Manually remove problematic packages using PowerShell
4. Reboot and try again

---

**Updated:** December 5, 2025  
**Script Version:** Win11-SysprepCleanup.ps1 v2.0
