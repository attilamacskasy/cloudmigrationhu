<#  Disable Hyper-V & VBS for VMware Workstation (Windows 11)
    Save as Disable-HyperV-For-Workstation.ps1 and run as Administrator.
#>

# --- Safety & env checks ---
# Require admin
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
    ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "Please run this script in an elevated PowerShell (Run as Administrator)."
    exit 1
}

Write-Host "Disabling Hyper-V, WHP, VMP, Sandbox, and VBS/HVCI..." -ForegroundColor Cyan

# --- Stop Hyper-V services if present (best-effort) ---
$svc = "vmcompute","vmms"
foreach ($s in $svc) {
    if (Get-Service -Name $s -ErrorAction SilentlyContinue) {
        Stop-Service -Name $s -Force -ErrorAction SilentlyContinue
        Set-Service  -Name $s -StartupType Disabled -ErrorAction SilentlyContinue
    }
}

# --- Disable optional features (use DISM for reliability) ---
$featuresToDisable = @(
    "Microsoft-Hyper-V-All",            # Entire Hyper-V stack
    "Microsoft-Hyper-V-Hypervisor",
    "Microsoft-Hyper-V-Management-Clients",
    "Microsoft-Hyper-V-Management-PowerShell",
    "VirtualMachinePlatform",           # Required by WSL2; uses Hyper-V
    "WindowsHypervisorPlatform",        # WHP forces VMware to ride on Hyper-V
    "Containers-DisposableClientVM",    # Windows Sandbox
    "Containers"                        # Windows Containers use Hyper-V isolation
    # Optional: uncomment to disable WSL completely:
    # "Microsoft-Windows-Subsystem-Linux"
)

foreach ($feat in $featuresToDisable) {
    Write-Host "Disabling feature: $feat"
    & dism /online /disable-feature /featurename:$feat /norestart | Out-Null
}

# --- Turn off Hyper-V boot launch ---
Write-Host "Setting boot hypervisorlaunchtype to OFF"
bcdedit /set hypervisorlaunchtype off | Out-Null

# --- Disable VBS / Device Guard / HVCI (Memory Integrity) ---
# These registry keys control VBS and HVCI on client SKUs.
# They will be applied even if the keys don't exist yet.
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

# (Optional) Turn off Credential Guard if it was enabled via LSA config (best-effort)
$lsakey = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa"
if (Test-Path $lsakey) {
    # LsaCfgFlags: 0 = Disabled, 1/2 = Enabled with/without UEFI lock
    Set-ItemProperty -Path $lsakey -Name LsaCfgFlags -Type DWord -Value 0 -ErrorAction SilentlyContinue
}

# --- Report current states ---
Write-Host "`nCurrent relevant feature states:" -ForegroundColor Yellow
Get-WindowsOptionalFeature -Online |
    Where-Object { $_.FeatureName -in $featuresToDisable } |
    Select-Object FeatureName, State |
    Format-Table -AutoSize

Write-Host "`nAll changes staged. A reboot is required to fully unload Hyper-V & VBS." -ForegroundColor Green

# --- Prompt for reboot ---
$choice = Read-Host "Reboot now? (Y/N)"
if ($choice -match '^(y|yes)$') {
    Restart-Computer -Force
} else {
    Write-Host "Please reboot before installing VMware Workstation for native hardware access." -ForegroundColor Yellow
}
