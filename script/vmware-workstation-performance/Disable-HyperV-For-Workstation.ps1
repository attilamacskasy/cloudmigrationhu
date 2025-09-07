<#
.SYNOPSIS
    Disables Hyper-V, Windows Hypervisor Platform, Virtual Machine Platform,
    Windows Sandbox, and Virtualization-Based Security (VBS/HVCI) to ensure
    VMware Workstation has direct access to hardware for maximum performance.

.DESCRIPTION
    Windows 11 enables Hyper-V and virtualization-based security (VBS/HVCI)
    on modern CPUs by default. This causes VMware Workstation to run on top
    of the Windows Hypervisor Platform, reducing performance and compatibility.
    
    This script disables:
        - Hyper-V and related services
        - Windows Hypervisor Platform (WHP)
        - Virtual Machine Platform (VMP)
        - Windows Sandbox
        - Device Guard / Credential Guard
        - VBS / HVCI (Memory Integrity)

    It also sets the boot configuration so the Hyper-V hypervisor does not launch.

.NOTES
    Author: CloudMigration.hu Lab
    Filename: Disable-HyperV-For-Workstation.ps1
    Run As: Administrator
    Reboot: Required after execution
    Usage:  Run before installing or using VMware Workstation for best performance.

.LINK
    Re-enable script: Enable-HyperV-For-Workstation.ps1
    Microsoft Docs: https://learn.microsoft.com/en-us/windows/security/identity-protection/credential-guard/credential-guard-manage
#>

# --- Admin check ---
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
    ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "Please run this script in an elevated PowerShell (Run as Administrator)."
    exit 1
}

Write-Host "Disabling Hyper-V, WHP, VMP, Sandbox, and VBS/HVCI..." -ForegroundColor Cyan

# --- Stop Hyper-V services if running ---
$svc = "vmcompute","vmms"
foreach ($s in $svc) {
    if (Get-Service -Name $s -ErrorAction SilentlyContinue) {
        Stop-Service -Name $s -Force -ErrorAction SilentlyContinue
        Set-Service  -Name $s -StartupType Disabled -ErrorAction SilentlyContinue
    }
}

# --- Disable Windows features ---
$featuresToDisable = @(
    "Microsoft-Hyper-V-All",            # Entire Hyper-V stack
    "Microsoft-Hyper-V-Hypervisor",
    "Microsoft-Hyper-V-Management-Clients",
    "Microsoft-Hyper-V-Management-PowerShell",
    "VirtualMachinePlatform",           # Required by WSL2; uses Hyper-V
    "WindowsHypervisorPlatform",        # WHP forces VMware to ride on Hyper-V
    "Containers-DisposableClientVM",    # Windows Sandbox
    "Containers"                        # Containers use Hyper-V isolation
    # Optional: disable WSL completely:
    # "Microsoft-Windows-Subsystem-Linux"
)

foreach ($feat in $featuresToDisable) {
    Write-Host "Disabling feature: $feat"
    & dism /online /disable-feature /featurename:$feat /norestart | Out-Null
}

# --- Prevent Hyper-V from loading at boot ---
Write-Host "Setting boot hypervisorlaunchtype to OFF"
bcdedit /set hypervisorlaunchtype off | Out-Null

# --- Disable VBS / Device Guard / HVCI ---
$dgBase   = "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard"
$hvciKey  = Join-Path $dgBase "Scenarios\HypervisorEnforcedCodeIntegrity"

New-Item -Path $dgBase  -Force | Out-Null
New-Item -Path $hvciKey -Force | Out-Null

# Disable VBS
Set-ItemProperty -Path $dgBase -Name EnableVirtualizationBasedSecurity -Type DWord -Value 0
# Make platform security not required
Set-ItemProperty -Path $dgBase -Name RequirePlatformSecurityFeatures -Type DWord -Value 0 -ErrorAction SilentlyContinue
# Disable HVCI (Memory Integrity)
Set-ItemProperty -Path $hvciKey -Name Enabled -Type DWord -Value 0

# Disable Credential Guard (best-effort)
$lsakey = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa"
if (Test-Path $lsakey) {
    Set-ItemProperty -Path $lsakey -Name LsaCfgFlags -Type DWord -Value 0 -ErrorAction SilentlyContinue
}

# --- Report feature states ---
Write-Host "`nFeature states after disable attempt:" -ForegroundColor Yellow
Get-WindowsOptionalFeature -Online |
    Where-Object { $_.FeatureName -in $featuresToDisable } |
    Select-Object FeatureName, State |
    Format-Table -AutoSize

Write-Host "`nAll changes staged. Please reboot to unload Hyper-V & VBS completely." -ForegroundColor Green
