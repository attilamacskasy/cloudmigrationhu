<#

    Start with
    Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force

    Windows 11 Sysprep Compatibility Cleanup Script
    ------------------------------------------------
    - Temporarily disables Cloudbase-Init services
    - Turns off BitLocker on OS volume (C:) if needed
    - Removes common Sysprep-blocking AppX / provisioned packages
    - Optionally runs Sysprep: /generalize /oobe /shutdown

    Usage:
      1) Right-click PowerShell → Run as Administrator
      2) .\Win11-SysprepCleanup.ps1
         or:
         .\Win11-SysprepCleanup.ps1 -RunSysprep
#>

param(
    [switch]$RunSysprep
)

#region Check for admin rights
if (-not ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent()
    ).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {

    Write-Host "This script must be run as Administrator. Exiting..." -ForegroundColor Red
    exit 1
}
#endregion

Write-Host "=== Windows 11 Sysprep Compatibility Cleanup starting ===" -ForegroundColor Cyan

#region Temporarily disable Cloudbase-Init services
$cbServices = @("cloudbase-init", "cloudbase-init-unattend")

foreach ($svcName in $cbServices) {
    $svc = Get-Service -Name $svcName -ErrorAction SilentlyContinue
    if ($svc) {
        Write-Host "Stopping and disabling Cloudbase service: $svcName" -ForegroundColor Yellow
        try {
            if ($svc.Status -ne 'Stopped') {
                Stop-Service -Name $svcName -Force -ErrorAction SilentlyContinue
            }
            Set-Service -Name $svcName -StartupType Disabled -ErrorAction SilentlyContinue
        } catch {
            Write-Host "  Failed to modify service '$svcName': $($_.Exception.Message)" -ForegroundColor DarkYellow
        }
    }
}
#endregion

#region Turn off BitLocker on C: if needed
function Disable-OsBitLockerIfNeeded {
    Write-Host "`nChecking BitLocker status on C: ..." -ForegroundColor Cyan
    $bitlockerOff = $false

    try {
        if (Get-Command Get-BitLockerVolume -ErrorAction SilentlyContinue) {
            # Using BitLocker PowerShell module
            $vol = Get-BitLockerVolume -MountPoint 'C:' -ErrorAction SilentlyContinue
            if ($vol) {
                if ($vol.ProtectionStatus -eq 'Off' -or $vol.VolumeStatus -eq 'FullyDecrypted') {
                    Write-Host "  BitLocker is already OFF on C:." -ForegroundColor Green
                    $bitlockerOff = $true
                } else {
                    Write-Host "  BitLocker is ON, disabling it on C: ..." -ForegroundColor Yellow
                    Disable-BitLocker -MountPoint 'C:' | Out-Null
                }
            }
        } else {
            # Fallback: manage-bde
            $status = & manage-bde.exe -status C: 2>$null
            if ($status -match "Protection Status:\s+Protection Off") {
                Write-Host "  BitLocker is already OFF on C:." -ForegroundColor Green
                $bitlockerOff = $true
            } elseif ($status) {
                Write-Host "  BitLocker is ON, disabling it on C: via manage-bde..." -ForegroundColor Yellow
                & manage-bde.exe -off C: | Out-Null
            }
        }

        if (-not $bitlockerOff) {
            # Wait until decryption completes
            Write-Host "  Waiting for full BitLocker decryption..." -ForegroundColor Yellow
            while ($true) {
                Start-Sleep -Seconds 10
                if (Get-Command Get-BitLockerVolume -ErrorAction SilentlyContinue) {
                    $vol = Get-BitLockerVolume -MountPoint 'C:' -ErrorAction SilentlyContinue
                    if ($vol -and $vol.VolumeStatus -eq 'FullyDecrypted') { break }
                } else {
                    $status = & manage-bde.exe -status C: 2>$null
                    if ($status -match "Percentage Encrypted:\s+0%") { break }
                }
                Write-Host "    ...BitLocker is still decrypting C: ..." -ForegroundColor DarkYellow
            }
            Write-Host "  BitLocker is now fully disabled on C:." -ForegroundColor Green
        }
    }
    catch {
        Write-Host "  Error while checking/disabling BitLocker: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Disable-OsBitLockerIfNeeded
#endregion

#region Remove Sysprep-blocking AppX packages
Write-Host "`nRemoving known Sysprep-blocking AppX packages..." -ForegroundColor Cyan

# Typical Sysprep-blocker patterns on Windows 10/11
$appPatterns = @(
    "*handwriting*",
    "Microsoft.Ink.Handwriting*",
    "Microsoft.Xbox*",
    "Microsoft.GamingApp*",
    "Microsoft.OneConnect*",
    "Microsoft.SkypeApp*",
    "Microsoft.GetHelp*",
    "Microsoft.Getstarted*",
    "Microsoft.ZuneMusic*",
    "Microsoft.ZuneVideo*",
    "Microsoft.BingNews*",
    "Microsoft.BingWeather*",
    "Microsoft.Microsoft3DViewer*",
    "Microsoft.MSPaint*",
    "Microsoft.Print3D*",
    "Microsoft.WindowsMaps*",
    "Microsoft.MicrosoftOfficeHub*",
    "Microsoft.People*",
    "Microsoft.SolitaireCollection*",
    "Microsoft.MixedReality.Portal*",
    "Microsoft.YourPhone*"
)

foreach ($pattern in $appPatterns) {
    Write-Host "  Processing packages matching: $pattern" -ForegroundColor Yellow

    # Remove AppX for all users
    $apps = Get-AppxPackage -AllUsers -ErrorAction SilentlyContinue | Where-Object { $_.Name -like $pattern }
    foreach ($app in $apps) {
        Write-Host "    Removing AppxPackage (AllUsers): $($app.Name)" -ForegroundColor DarkYellow
        try {
            Remove-AppxPackage -Package $app.PackageFullName -AllUsers -ErrorAction SilentlyContinue
        } catch {
            Write-Host "      Failed to remove AppxPackage: $($_.Exception.Message)" -ForegroundColor DarkRed
        }
    }

    # Remove provisioned packages (for new users)
    $provApps = Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue |
                Where-Object { $_.DisplayName -like $pattern }
    foreach ($prov in $provApps) {
        Write-Host "    Removing Provisioned package: $($prov.DisplayName)" -ForegroundColor DarkYellow
        try {
            Remove-AppxProvisionedPackage -Online -PackageName $prov.PackageName -ErrorAction SilentlyContinue | Out-Null
        } catch {
            Write-Host "      Failed to remove provisioned package: $($_.Exception.Message)" -ForegroundColor DarkRed
        }
    }
}

Write-Host "AppX cleanup finished. A quick reboot before Sysprep is recommended." -ForegroundColor Green
#endregion

#region Optionally run Sysprep
if ($RunSysprep) {
    Write-Host "`nRunning Sysprep: /generalize /oobe /shutdown" -ForegroundColor Cyan
    Write-Host "IMPORTANT: After Sysprep shuts down the VM, DO NOT boot it again; convert it to a template in Proxmox." -ForegroundColor Yellow

    try {
        & "$env:WINDIR\System32\Sysprep\Sysprep.exe" /generalize /oobe /shutdown
    } catch {
        Write-Host "Sysprep failed to launch: $($_.Exception.Message)" -ForegroundColor Red
    }
} else {
    Write-Host "`nCleanup complete. You should now:" -ForegroundColor Cyan
    Write-Host "  1) Reboot the VM once (optional but recommended)" -ForegroundColor White
    Write-Host "  2) Then manually run Sysprep:" -ForegroundColor White
    Write-Host "       $env:WINDIR\System32\Sysprep\Sysprep.exe /generalize /oobe /shutdown" -ForegroundColor Yellow
    Write-Host "  3) When the VM shuts down, convert it to a Proxmox template." -ForegroundColor White
}
#endregion

Write-Host "`n=== Cleanup script finished ===" -ForegroundColor Cyan
