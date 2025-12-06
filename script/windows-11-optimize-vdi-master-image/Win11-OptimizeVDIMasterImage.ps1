<#
  Windows 11 Master Image Optimization Script
  -------------------------------------------
  - Designed for VM templates / VDI golden images
  - Interactive: shows each step, explains why, prints the commands,
    and asks for confirmation (Y/N) before running anything.
#>

# ---------- Helper: check for admin rights ----------
$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "This script must be run as Administrator. Exiting..." -ForegroundColor Red
    exit 1
}

# ---------- Helper: ask user before each step ----------
function Invoke-InteractiveStep {
    param(
        [string]$Name,
        [string]$Why,
        [string]$CommandText,
        [string]$VerifyText = ""
    )

    Write-Host ""
    Write-Host "==================================================================" -ForegroundColor DarkCyan
    Write-Host "STEP: $Name" -ForegroundColor Cyan
    Write-Host "WHY : $Why" -ForegroundColor Yellow
    Write-Host "------------------------------------------------------------------" -ForegroundColor DarkCyan
    Write-Host "Command(s) to run:" -ForegroundColor Yellow
    Write-Host $CommandText -ForegroundColor Gray
    Write-Host "==================================================================" -ForegroundColor DarkCyan

    $answer = Read-Host "Run this step? (Y/N)"
    if ($answer -match '^[Yy]') {
        try {
            Invoke-Expression $CommandText
            Write-Host "Step '$Name' completed." -ForegroundColor Green

            if ($VerifyText -and $VerifyText.Trim().Length -gt 0) {
                Write-Host ""
                Write-Host "Verification commands for '$Name':" -ForegroundColor Yellow
                Write-Host $VerifyText -ForegroundColor Gray
                $vAnswer = Read-Host "Run verification now? (Y/N)"
                if ($vAnswer -match '^[Yy]') {
                    Invoke-Expression $VerifyText
                }
            }
        }
        catch {
            Write-Host "Error while running step '$Name': $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    else {
        Write-Host "Step '$Name' was skipped by user." -ForegroundColor DarkYellow
    }
}

Write-Host "=== Windows 11 Master Image Optimization ===" -ForegroundColor Cyan
Write-Host "This script will show each optimization step and ask before running it." -ForegroundColor White
Write-Host ""

# ---------- Define steps ----------

$steps = @()

# 1) Disable hibernation
$steps += [PSCustomObject]@{
    Name  = "Disable hibernation"
    Why   = "Hibernation is not needed on VM templates, wastes disk space and can interfere with Fast Startup and imaging."
    Cmd   = @"
powercfg /h off
"@
    Verify = @"
powercfg /a
"@
}

# 2) Disable Fast Startup (Hiberboot)
$steps += [PSCustomObject]@{
    Name  = "Disable Fast Startup (Hiberboot)"
    Why   = "Fast Startup can cause issues with sysprepped images, dual-boot and some hypervisor scenarios. Safer to turn off on templates."
    Cmd   = @"
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power' -Name HiberbootEnabled -Value 0 -Type DWord
"@
    Verify = @"
Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power' -Name HiberbootEnabled
"@
}

# 3) Set power plan to High performance and disable sleep
$steps += [PSCustomObject]@{
    Name  = "Set power plan (High performance, no sleep)"
    Why   = "For VMs and VDI we usually want no sleep/hibernate and a consistent performance-oriented power profile."
    Cmd   = @"
# Try to set High performance as active power scheme (if exists)
$highPerf = powercfg -l | Select-String -Pattern 'High performance'
if ($highPerf) {
    \$guid = (\$highPerf.ToString().Split()[3]).Trim()
    powercfg -setactive \$guid
}
# Disable display and system sleep on AC power
powercfg -change -monitor-timeout-ac 0
powercfg -change -standby-timeout-ac 0
powercfg -change -hibernate-timeout-ac 0
"@
    Verify = @"
powercfg /l
powercfg /q
"@
}

# 4) Disable Xbox / GameDVR / GameBar features
$steps += [PSCustomObject]@{
    Name  = "Disable Xbox / GameDVR / GameBar features"
    Why   = "Gaming features are unnecessary on enterprise templates and may consume CPU/RAM."
    Cmd   = @"
# Disable GameDVR and GameBar via registry
New-Item -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows' -Name 'GameDVR' -Force | Out-Null
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR' -Name 'AllowGameDVR' -Type DWord -Value 0

New-Item -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows' -Name 'GameBar' -Force | Out-Null
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameBar' -Name 'AllowGameBar' -Type DWord -Value 0
"@
    Verify = @"
Get-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR'
Get-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameBar'
"@
}

# 5) Optional AppX bloat removal
$steps += [PSCustomObject]@{
    Name  = "Remove common consumer AppX bloat (optional)"
    Why   = "Removes some non-essential Windows Store apps (Xbox, 3D, mixed reality, etc.). Core apps like Store, Photos, Calculator are kept."
    Cmd   = @"
# Patterns of non-essential apps, adjust if needed
\$patterns = @(
    'Microsoft.Xbox*',
    'Microsoft.GamingApp*',
    'Microsoft.ZuneMusic*',
    'Microsoft.ZuneVideo*',
    'Microsoft.Microsoft3DViewer*',
    'Microsoft.MSPaint*',
    'Microsoft.Print3D*',
    'Microsoft.MixedReality.Portal*',
    'Microsoft.SkypeApp*',
    'Microsoft.GetHelp*',
    'Microsoft.Getstarted*',
    'Microsoft.SolitaireCollection*',
    'Microsoft.People*',
    'Microsoft.BingWeather*',
    'Microsoft.BingNews*'
)

foreach (\$p in \$patterns) {
    Write-Host "Trying to remove AppX packages matching: \$p" -ForegroundColor Yellow
    Get-AppxPackage -AllUsers -ErrorAction SilentlyContinue | Where-Object { \$_.Name -like \$p } | ForEach-Object {
        Write-Host "  Removing package: \$($_.Name)" -ForegroundColor DarkYellow
        try {
            Remove-AppxPackage -Package \$_.PackageFullName -AllUsers -ErrorAction SilentlyContinue
        } catch {
            Write-Host "    Failed to remove: \$($_.Exception.Message)" -ForegroundColor Red
        }
    }
}
"@
    Verify = @"
Get-AppxPackage -AllUsers | Select-Object Name | Sort-Object Name
"@
}

# 6) Limit Delivery Optimization (Windows Update P2P)
$steps += [PSCustomObject]@{
    Name  = "Limit Delivery Optimization (Windows Update P2P)"
    Why   = "Prevents the VM from acting as a peer-to-peer update source and wasting bandwidth."
    Cmd   = @"
New-Item -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows' -Name 'DeliveryOptimization' -Force | Out-Null
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization' -Name 'DODownloadMode' -Type DWord -Value 0
"@
    Verify = @"
Get-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization'
"@
}

# 7) Disable background apps (UWP)
$steps += [PSCustomObject]@{
    Name  = "Disable background apps (modern/UWP)"
    Why   = "Reduces background CPU/network usage from Store apps that don't need to run in the background on templates."
    Cmd   = @"
New-Item -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows' -Name 'AppPrivacy' -Force | Out-Null
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy' -Name 'LetAppsRunInBackground' -Type DWord -Value 2
"@
    Verify = @"
Get-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy'
"@
}

# 8) Basic disk cleanup using cleanmgr
$steps += [PSCustomObject]@{
    Name  = "Basic disk cleanup (Temp, Recycle Bin, old updates)"
    Why   = "Frees disk space on the master image by cleaning temp files and some update caches."
    Cmd   = @"
# Configure cleanmgr sageset 1 (this opens once; user may have to pre-configure on first run)
cleanmgr.exe /sagerun:1
"@
    Verify = @"
Get-PSDrive -PSProvider FileSystem
"@
}

# 9) Enable RDP (optional, for admin/VDI access)
$steps += [PSCustomObject]@{
    Name  = "Enable Remote Desktop (RDP)"
    Why   = "Allows remote administration / VDI access over RDP. Firewall rule for RDP will be enabled."
    Cmd   = @"
# Enable RDP
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server' -Name 'fDenyTSConnections' -Value 0
# Enable firewall rule for RDP
Enable-NetFirewallRule -DisplayGroup 'Remote Desktop' -ErrorAction SilentlyContinue
"@
    Verify = @"
Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server' -Name 'fDenyTSConnections'
Get-NetFirewallRule -DisplayGroup 'Remote Desktop'
"@
}

# ---------- Show plan ----------
Write-Host "Planned optimization steps:" -ForegroundColor Cyan
$idx = 1
foreach ($s in $steps) {
    Write-Host ("{0}. {1}" -f $idx, $s.Name) -ForegroundColor White
    Write-Host ("   -> {0}" -f $s.Why) -ForegroundColor DarkGray
    $idx++
}
Write-Host ""
Read-Host "Press ENTER to start interactive execution..."

# ---------- Execute steps interactively ----------
foreach ($step in $steps) {
    Invoke-InteractiveStep -Name $step.Name -Why $step.Why -CommandText $step.Cmd -VerifyText $step.Verify
}

Write-Host ""
Write-Host "=== Optimization script finished. ===" -ForegroundColor Cyan
Write-Host "You may want to reboot the VM once before running Sysprep again." -ForegroundColor Yellow
