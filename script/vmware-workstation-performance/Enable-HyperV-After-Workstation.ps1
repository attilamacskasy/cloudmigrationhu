<#
.SYNOPSIS
    Re-enables Hyper-V, Windows Hypervisor Platform, Virtual Machine Platform,
    Windows Sandbox, and Virtualization-Based Security (VBS/HVCI) after they
    were disabled for VMware Workstation performance.

.DESCRIPTION
    This script restores Microsoft’s virtualization stack and security features:
        - Hyper-V and related services
        - Windows Hypervisor Platform (WHP)
        - Virtual Machine Platform (VMP)
        - Windows Sandbox
        - Device Guard / Credential Guard
        - VBS / HVCI (Memory Integrity)

    It also sets the boot configuration so the Hyper-V hypervisor launches again.

.NOTES
    Author: CloudMigration.hu Lab
    Filename: Enable-HyperV-For-Workstation.ps1
    Run As: Administrator
    Reboot: Required after execution
    Usage:  Run after VMware Workstation is no longer needed or
            when you want to restore Hyper-V and security features.

.LINK
    Disable script: Disable-HyperV-For-Workstation.ps1
    Microsoft Docs: https://learn.microsoft.com/en-us/virtualization/hyper-v-on-windows/about/
#>

# --- Admin check ---
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
    ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "Please run this script in an elevated PowerShell (Run as Administrator)."
    exit 1
}

Write-Host "Re-enabling Hyper-V, WHP, VMP, Sandbox, and VBS/HVCI..." -ForegroundColor Cyan

# --- Re-enable Windows features ---
$featuresToEnable = @(
    "Microsoft-Hyper-V-All",            # Entire Hyper-V stack
    "VirtualMachinePlatform",           # Required by WSL2
    "WindowsHypervisorPlatform",        # WHP API
    "Containers-DisposableClientVM"     # Windows Sandbox
    # Optional: uncomment to enable WSL again
    # "Microsoft-Windows-Subsystem-Linux"
)

foreach ($feat in $featuresToEnable) {
    Write-Host "Enabling feature: $feat"
    & dism /online /enable-feature /featurename:$feat /all /norestart | Out-Null
}

# --- Ensure Hyper-V hypervisor starts at boot ---
Write-Host "Setting boot hypervisorlaunchtype to AUTO"
bcdedit /set hypervisorlaunchtype auto | Out-Null

# --- Re-enable VBS / Device Guard / HVCI ---
$dgBase   = "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard"
$hvciKey  = Join-Path $dgBase "Scenarios\HypervisorEnforcedCodeIntegrity"

New-Item -Path $dgBase  -Force | Out-Null
New-Item -Path $hvciKey -Force | Out-Null

# Enable VBS
Set-ItemProperty -Path $dgBase -Name EnableVirtualizationBasedSecurity -Type DWord -Value 1
# Require Secure Boot / TPM if supported
Set-ItemProperty -Path $dgBase -Name RequirePlatformSecurityFeatures -Type DWord -Value 1 -ErrorAction SilentlyContinue
# Enable HVCI (Memory Integrity)
Set-ItemProperty -Path $hvciKey -Name Enabled -Type DWord -Value 1

# Enable Credential Guard (best-effort)
$lsakey = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa"
if (Test-Path $lsakey) {
    Set-ItemProperty -Path $lsakey -Name LsaCfgFlags -Type DWord -Value 1 -ErrorAction SilentlyContinue
}

# --- Report feature states ---
Write-Host "`nFeature states after enable attempt:" -ForegroundColor Yellow
Get-WindowsOptionalFeature -Online |
    Where-Object { $_.FeatureName -in $featuresToEnable } |
    Select-Object FeatureName, State |
    Format-Table -AutoSize

Write-Host "`nAll changes staged. Please reboot to fully re-enable Hyper-V & VBS." -ForegroundColor Green
