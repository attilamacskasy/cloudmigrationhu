<#
    Start with
    Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force

    Windows 11 Sysprep Compatibility Cleanup Script
    ------------------------------------------------
    This script helps prepare a Windows 11 VM for Proxmox template creation.
    
    WORKFLOW FOR PROXMOX IMAGE PREPARATION:
    ========================================
    
    Step 1: Initial Setup (BEFORE installing applications)
    -------------------------------------------------------
    .\Win11-SysprepCleanup.ps1 -CloudbaseAction Disable
    
    This disables cloudbase-init services so they don't interfere during:
    - Application installations
    - Windows updates
    - Custom configurations
    - Software deployment
    
    Step 2: Install Your Applications & Prerequisites
    --------------------------------------------------
    After cloudbase-init is disabled, perform all your customizations:
    - Install applications (Office, browsers, utilities, etc.)
    - Apply Windows updates
    - Configure settings
    - Install prerequisites
    
    Step 3: Final Preparation (AFTER all installations complete)
    -------------------------------------------------------------
    .\Win11-SysprepCleanup.ps1 -CloudbaseAction Enable -RunSysprep
    
    This will:
    - Re-enable cloudbase-init services (required for Proxmox cloud-init)
    - Turn off BitLocker on C: drive
    - Remove Sysprep-blocking AppX packages
    - Run optional user-only AppX scan when requested
    - Run Sysprep to generalize the image
    - Shutdown the VM
    
    Step 4: Convert to Proxmox Template
    ------------------------------------
    After the VM shuts down:
    - DO NOT boot the VM again
    - Convert it to a Proxmox template
    - Use cloud-init for future VM deployments
    
    PARAMETERS:
    -----------
    -CloudbaseAction <String>
        Check   : Display current cloudbase-init service status
        Disable : Stop and disable cloudbase-init services
        Enable  : Enable and set cloudbase-init to automatic startup
        
    -RunSysprep <Switch>
        Run Sysprep /generalize /oobe /shutdown after cleanup

    -UnattendLanguage <String>
        Optional. When specified together with -RunSysprep, generates
        C:\Windows\System32\Sysprep\unattend.xml and runs Sysprep with
        /unattend:C:\Windows\System32\Sysprep\unattend.xml.
        Supported values:
          - en-US  : English (United States)
          - hu-HU  : Hungarian
    
    -ScanUserPackages <Switch>
        When supplied, detects and removes AppX packages installed for a single user only
        (These scans can take several minutes; disabled by default.)
        
    USAGE EXAMPLES:
    ---------------
    # Check cloudbase-init service status
    .\Win11-SysprepCleanup.ps1 -CloudbaseAction Check
    
    # Disable cloudbase-init before installing apps
    .\Win11-SysprepCleanup.ps1 -CloudbaseAction Disable
    
    # Enable cloudbase-init and prepare for final sysprep
    .\Win11-SysprepCleanup.ps1 -CloudbaseAction Enable -RunSysprep
    
    # Just cleanup without sysprep (manual sysprep later)
    .\Win11-SysprepCleanup.ps1 -CloudbaseAction Enable

    # Run the deep user-only AppX scan (optional)
    .\Win11-SysprepCleanup.ps1 -CloudbaseAction Enable -ScanUserPackages

    # Run Sysprep with generated unattend.xml in Hungarian
    .\Win11-SysprepCleanup.ps1 -CloudbaseAction Enable -RunSysprep -UnattendLanguage hu-HU

    # Run Sysprep with generated unattend.xml in English (en-US)
    .\Win11-SysprepCleanup.ps1 -CloudbaseAction Enable -RunSysprep -UnattendLanguage en-US
#>

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet('Check', 'Disable', 'Enable')]
    [string]$CloudbaseAction = 'Disable',
    
    [switch]$RunSysprep,

    [switch]$ScanUserPackages,

    [ValidateSet('en-US', 'hu-HU')]
    [string]$UnattendLanguage
)

#region Check for admin rights
if (-not ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent()
    ).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {

    Write-Host "This script must be run as Administrator. Exiting..." -ForegroundColor Red
    exit 1
}
#endregion

Write-Host "=== Windows 11 Sysprep Compatibility Cleanup ===" -ForegroundColor Cyan
Write-Host "Cloudbase-Init Action: $CloudbaseAction" -ForegroundColor White

#region Manage Cloudbase-Init services
function Get-CloudbaseServiceStatus {
    param([string]$ServiceName)
    
    $svc = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
    if ($svc) {
        return @{
            Exists = $true
            Status = $svc.Status
            StartType = $svc.StartType
            DisplayName = $svc.DisplayName
        }
    }
    return @{ Exists = $false }
}

function Show-CloudbaseStatus {
    Write-Host "`n=== Cloudbase-Init Service Status ===" -ForegroundColor Cyan
    
    $cbServices = @("cloudbase-init", "cloudbase-init-unattend")
    $allFound = $false
    
    foreach ($svcName in $cbServices) {
        $status = Get-CloudbaseServiceStatus -ServiceName $svcName
        if ($status.Exists) {
            $allFound = $true
            Write-Host "`nService: $($status.DisplayName)" -ForegroundColor Yellow
            Write-Host "  Name:       $svcName" -ForegroundColor White
            Write-Host "  Status:     $($status.Status)" -ForegroundColor $(if ($status.Status -eq 'Running') { 'Green' } else { 'DarkYellow' })
            Write-Host "  Start Type: $($status.StartType)" -ForegroundColor $(if ($status.StartType -eq 'Automatic') { 'Green' } else { 'DarkYellow' })
        }
    }
    
    if (-not $allFound) {
        Write-Host "`nNo cloudbase-init services found on this system." -ForegroundColor DarkYellow
        Write-Host "This is expected if cloudbase-init is not installed." -ForegroundColor DarkGray
    }
    
    Write-Host "`n======================================`n" -ForegroundColor Cyan
}

function Disable-CloudbaseServices {
    Write-Host "`n--- Disabling Cloudbase-Init Services ---" -ForegroundColor Yellow
    $cbServices = @("cloudbase-init", "cloudbase-init-unattend")
    $anyModified = $false

    foreach ($svcName in $cbServices) {
        $svc = Get-Service -Name $svcName -ErrorAction SilentlyContinue
        if ($svc) {
            $anyModified = $true
            Write-Host "Processing service: $svcName" -ForegroundColor White
            try {
                if ($svc.Status -ne 'Stopped') {
                    Write-Host "  Stopping service..." -ForegroundColor DarkYellow
                    Stop-Service -Name $svcName -Force -ErrorAction Stop
                }
                Write-Host "  Setting startup type to Disabled..." -ForegroundColor DarkYellow
                Set-Service -Name $svcName -StartupType Disabled -ErrorAction Stop
                Write-Host "  Success: Service stopped and disabled." -ForegroundColor Green
            } catch {
                Write-Host "  Failed to modify service '$svcName': $($_.Exception.Message)" -ForegroundColor Red
            }
        }
    }
    
    if (-not $anyModified) {
        Write-Host "No cloudbase-init services found to disable." -ForegroundColor DarkYellow
    } else {
        Write-Host "`nCloudbase-init services have been disabled." -ForegroundColor Green
        Write-Host "You can now safely install applications and configure the system." -ForegroundColor Cyan
    }
}

function Enable-CloudbaseServices {
    Write-Host "`n--- Enabling Cloudbase-Init Services ---" -ForegroundColor Yellow
    $cbServices = @("cloudbase-init", "cloudbase-init-unattend")
    $anyModified = $false

    foreach ($svcName in $cbServices) {
        $svc = Get-Service -Name $svcName -ErrorAction SilentlyContinue
        if ($svc) {
            $anyModified = $true
            Write-Host "Processing service: $svcName" -ForegroundColor White
            try {
                Write-Host "  Setting startup type to Automatic..." -ForegroundColor DarkYellow
                Set-Service -Name $svcName -StartupType Automatic -ErrorAction Stop
                Write-Host "  Success: Service enabled (will start automatically on next boot)." -ForegroundColor Green
            } catch {
                Write-Host "  Failed to modify service '$svcName': $($_.Exception.Message)" -ForegroundColor Red
            }
        }
    }
    
    if (-not $anyModified) {
        Write-Host "No cloudbase-init services found to enable." -ForegroundColor DarkYellow
    } else {
        Write-Host "`nCloudbase-init services have been enabled." -ForegroundColor Green
        Write-Host "Services will start automatically after Sysprep and template deployment." -ForegroundColor Cyan
    }
}

# Execute the requested cloudbase action
switch ($CloudbaseAction) {
    'Check' {
        Show-CloudbaseStatus
        Write-Host "=== Script finished ===" -ForegroundColor Cyan
        exit 0
    }
    'Disable' {
        Disable-CloudbaseServices
    }
    'Enable' {
        Enable-CloudbaseServices
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
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "APPX PACKAGE CLEANUP FOR SYSPREP" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Note: Some system apps cannot be removed and will be skipped." -ForegroundColor DarkGray

# Counters for summary
$script:removedCount = 0
$script:skippedCount = 0
$script:failedCount = 0

# Function to check for AppX packages installed per-user but not provisioned
function Find-UserOnlyAppxPackages {
    Write-Host "`nScanning for user-installed packages not provisioned for all users..." -ForegroundColor Cyan
    
    $allUserPackages = Get-AppxPackage -AllUsers -ErrorAction SilentlyContinue
    $provisionedPackages = Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
    
    $userOnlyPackages = @()
    
    foreach ($pkg in $allUserPackages) {
        $isProvisioned = $provisionedPackages | Where-Object { $_.DisplayName -eq $pkg.Name }
        if (-not $isProvisioned) {
            $userOnlyPackages += $pkg
        }
    }
    
    if ($userOnlyPackages.Count -gt 0) {
        Write-Host "  Found $($userOnlyPackages.Count) user-only packages (Sysprep blockers):" -ForegroundColor Yellow
        foreach ($pkg in $userOnlyPackages) {
            Write-Host "    - $($pkg.Name)" -ForegroundColor DarkYellow
        }
        return $userOnlyPackages
    } else {
        Write-Host "  No user-only packages found." -ForegroundColor Green
        return @()
    }
}

# Typical Sysprep-blocker patterns on Windows 10/11
$appPatterns = @(
    # Language Experience Packs (CRITICAL for Sysprep)
    "Microsoft.LanguageExperiencePack*",
    
    # Handwriting and Ink
    "*handwriting*",
    "Microsoft.Ink.Handwriting*",
    
    # Gaming and Xbox
    "Microsoft.Xbox*",
    "Microsoft.GamingApp*",
    "Microsoft.GamingServices*",
    
    # Communication
    "Microsoft.OneConnect*",
    "Microsoft.SkypeApp*",
    "Microsoft.YourPhone*",
    "Microsoft.People*",
    
    # Help and Getting Started
    "Microsoft.GetHelp*",
    "Microsoft.Getstarted*",
    "Microsoft.Tips*",
    
    # Media
    "Microsoft.ZuneMusic*",
    "Microsoft.ZuneVideo*",
    
    # News and Weather
    "Microsoft.BingNews*",
    "Microsoft.BingWeather*",
    
    # 3D and Graphics
    "Microsoft.Microsoft3DViewer*",
    "Microsoft.MSPaint*",
    "Microsoft.Paint*",
    "Microsoft.Print3D*",
    "Microsoft.MixedReality.Portal*",
    
    # Office and Productivity
    "Microsoft.MicrosoftOfficeHub*",
    "Microsoft.Office.OneNote*",
    "Microsoft.OneNote*",
    
    # Maps and Location
    "Microsoft.WindowsMaps*",
    
    # Entertainment
    "Microsoft.SolitaireCollection*",
    "Microsoft.MicrosoftSolitaireCollection*",
    
    # Other potential blockers
    "Microsoft.Messaging*",
    "Microsoft.Windows.Photos*",
    "Microsoft.WindowsFeedbackHub*",
    "Microsoft.BingFinance*",
    "Microsoft.BingSports*",
    "Microsoft.WindowsAlarms*",
    "Microsoft.WindowsSoundRecorder*"
)

# Known system apps that cannot be removed (will be skipped silently)
$systemApps = @(
    "Microsoft.XboxGameCallableUI"
)

foreach ($pattern in $appPatterns) {
    Write-Host "`n  Processing packages matching: $pattern" -ForegroundColor Yellow

    # Remove AppX for all users
    $apps = Get-AppxPackage -AllUsers -ErrorAction SilentlyContinue | Where-Object { $_.Name -like $pattern }
    foreach ($app in $apps) {
        # Check if this is a known system app
        if ($systemApps -contains $app.Name) {
            Write-Host "    Skipping system app: $($app.Name)" -ForegroundColor DarkGray
            Write-Host "      (This is a protected Windows component)" -ForegroundColor DarkGray
            $script:skippedCount++
            continue
        }
        
        Write-Host "    Removing AppxPackage: $($app.Name)" -ForegroundColor White
        try {
            Remove-AppxPackage -Package $app.PackageFullName -AllUsers -ErrorAction Stop
            Write-Host "      [OK] Successfully removed" -ForegroundColor Green
            $script:removedCount++
        } catch {
            $errorMsg = $_.Exception.Message
            
            # Check for specific error codes
            if ($errorMsg -match "0x80070032" -or $errorMsg -match "part of Windows and cannot be uninstalled") {
                Write-Host "      [SKIP] Protected system app" -ForegroundColor DarkGray
                $script:skippedCount++
            } elseif ($errorMsg -match "not supported") {
                Write-Host "      [SKIP] Operation not supported" -ForegroundColor DarkGray
                $script:skippedCount++
            } else {
                Write-Host "      [FAIL] $errorMsg" -ForegroundColor DarkRed
                $script:failedCount++
            }
        }
    }

    # Remove provisioned packages (for new users)
    $provApps = Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue |
                Where-Object { $_.DisplayName -like $pattern }
    foreach ($prov in $provApps) {
        Write-Host "    Removing Provisioned package: $($prov.DisplayName)" -ForegroundColor White
        try {
            Remove-AppxProvisionedPackage -Online -PackageName $prov.PackageName -ErrorAction Stop | Out-Null
            Write-Host "      [OK] Successfully removed" -ForegroundColor Green
            $script:removedCount++
        } catch {
            $errorMsg = $_.Exception.Message
            
            if ($errorMsg -match "0x80070032" -or $errorMsg -match "part of Windows") {
                Write-Host "      [SKIP] Protected system package" -ForegroundColor DarkGray
                $script:skippedCount++
            } else {
                Write-Host "      [FAIL] $errorMsg" -ForegroundColor DarkRed
                $script:failedCount++
            }
        }
    }
}
# End of foreach ($pattern in $appPatterns)

# Scan and remove user-only packages (optional deep clean)
if ($ScanUserPackages) {
    Write-Host "`n========================================" -ForegroundColor Cyan
    $userOnlyPackages = Find-UserOnlyAppxPackages

    if ($userOnlyPackages.Count -gt 0) {
        Write-Host "`nRemoving user-only packages (CRITICAL for Sysprep)..." -ForegroundColor Yellow
        
        foreach ($pkg in $userOnlyPackages) {
            Write-Host "`n  Removing user-only package: $($pkg.Name)" -ForegroundColor White

            $removalSucceeded = $false
            $lastError = $null

            foreach ($scope in @('AllUsers', 'CurrentUser')) {
                try {
                    if ($scope -eq 'AllUsers') {
                        Remove-AppxPackage -Package $pkg.PackageFullName -AllUsers -ErrorAction Stop
                        Write-Host "    [OK] Removed from all users" -ForegroundColor Green
                    } else {
                        Remove-AppxPackage -Package $pkg.PackageFullName -ErrorAction Stop
                        Write-Host "    [OK] Removed from current user" -ForegroundColor Green
                    }

                    $script:removedCount++
                    $removalSucceeded = $true
                    break
                } catch {
                    $lastError = $_.Exception.Message

                    # Only log detailed error after attempting current user removal
                    if ($scope -eq 'CurrentUser') {
                        if ($lastError -match "0x80070032" -or $lastError -match "not supported") {
                            Write-Host "    [SKIP] Protected system component" -ForegroundColor DarkGray
                            $script:skippedCount++
                        } else {
                            Write-Host "    [FAIL] $lastError" -ForegroundColor DarkRed
                            $script:failedCount++
                        }
                    }
                }
            }

            if (-not $removalSucceeded -and -not ($lastError -match "0x80070032" -or $lastError -match "not supported")) {
                # If we got here, both removal attempts failed with a non-system error already counted
                if (-not $lastError) {
                    Write-Host "    [FAIL] Unknown error removing $($pkg.Name)" -ForegroundColor DarkRed
                    $script:failedCount++
                }
            }
        }
    } else {
        Write-Host "No user-only packages detected during deep scan." -ForegroundColor Green
    }
} else {
    Write-Host "`n(User-only package scan skipped. Re-run with -ScanUserPackages for a deep cleanup.)" -ForegroundColor DarkGray
}

# Summary
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "APPX PACKAGE REMOVAL SUMMARY" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Removed:  $script:removedCount packages" -ForegroundColor Green
Write-Host "  Skipped:  $script:skippedCount packages (system protected)" -ForegroundColor DarkGray
Write-Host "  Failed:   $script:failedCount packages" -ForegroundColor $(if ($script:failedCount -gt 0) { 'Red' } else { 'Green' })

if ($script:failedCount -gt 0) {
    Write-Host "`n[WARN] Some packages failed to remove. Review errors above." -ForegroundColor Yellow
    Write-Host "  This may cause Sysprep issues. Consider manual removal or troubleshooting." -ForegroundColor Yellow
    Write-Host "  Check C:\Windows\System32\Sysprep\Panther\setuperr.log for Sysprep errors." -ForegroundColor Yellow
} else {
    Write-Host "`n[OK] All problematic packages removed successfully!" -ForegroundColor Green
}

# Final verification - check if any user-only packages remain
Write-Host "`n--- Final Verification ---" -ForegroundColor Cyan
if ($ScanUserPackages) {
    $remainingUserOnly = Find-UserOnlyAppxPackages

    if ($remainingUserOnly.Count -gt 0) {
        Write-Host "`n[WARN] $($remainingUserOnly.Count) user-only packages still remain!" -ForegroundColor Red
        Write-Host "  These packages WILL cause Sysprep to fail:" -ForegroundColor Red
        foreach ($pkg in $remainingUserOnly) {
            Write-Host "    - $($pkg.Name)" -ForegroundColor Yellow
        }
        Write-Host "`n  Recommended actions:" -ForegroundColor Cyan
        Write-Host "    1. Try running this script again" -ForegroundColor White
        Write-Host "    2. Manually remove packages using:" -ForegroundColor White
        Write-Host '       Get-AppxPackage -Name ''PackageName'' -AllUsers | Remove-AppxPackage -AllUsers' -ForegroundColor DarkGray
        Write-Host "    3. Check Windows Event Viewer for AppX deployment errors" -ForegroundColor White
    } else {
        Write-Host "[OK] No user-only packages detected. System is ready for Sysprep!" -ForegroundColor Green
    }
} else {
    Write-Host "  Skipped (enable -ScanUserPackages to perform this check)." -ForegroundColor DarkGray
}

Write-Host "`nAppX cleanup finished." -ForegroundColor Cyan
Write-Host "IMPORTANT: Reboot before running Sysprep to ensure all changes take effect." -ForegroundColor Yellow
#endregion

#region Optionally run Sysprep
if ($RunSysprep) {
    $unattendPath = Join-Path $env:WINDIR 'System32\Sysprep\unattend.xml'

        if ($UnattendLanguage) {
                Write-Host "`nGenerating unattend.xml for language: $UnattendLanguage" -ForegroundColor Cyan

                $inputLocale  = $UnattendLanguage
                $systemLocale = $UnattendLanguage
                $userLocale   = $UnattendLanguage
                $uiLanguage   = $UnattendLanguage

                $unattendContent = @"
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend">

    <settings pass="oobeSystem">
        <component name="Microsoft-Windows-International-Core" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
            <InputLocale>$inputLocale</InputLocale>
            <SystemLocale>$systemLocale</SystemLocale>
            <UILanguage>$uiLanguage</UILanguage>
            <UILanguageFallback>$uiLanguage</UILanguageFallback>
            <UserLocale>$userLocale</UserLocale>
        </component>

        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
            <OOBE>
                <HideEULAPage>true</HideEULAPage>
                <HideOEMRegistrationScreen>true</HideOEMRegistrationScreen>
                <HideOnlineAccountScreens>true</HideOnlineAccountScreens>
                <HideWirelessSetupInOOBE>true</HideWirelessSetupInOOBE>
                <NetworkLocation>Work</NetworkLocation>
                <ProtectYourPC>1</ProtectYourPC>
                <SkipUserOOBE>true</SkipUserOOBE>
                <SkipMachineOOBE>true</SkipMachineOOBE>
            </OOBE>
            <RegisteredOwner>Administrator</RegisteredOwner>
            <RegisteredOrganization>Proxmox</RegisteredOrganization>
            <TimeZone>UTC</TimeZone>
        </component>

    </settings>

    <settings pass="generalize">
        <component name="Microsoft-Windows-Security-SPP" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
            <SkipRearm>1</SkipRearm>
        </component>
    </settings>

</unattend>
"@

        try {
            $sysprepDir = Split-Path $unattendPath -Parent
            if (-not (Test-Path $sysprepDir)) {
                New-Item -ItemType Directory -Path $sysprepDir -Force | Out-Null
            }

            $unattendContent | Set-Content -Path $unattendPath -Encoding UTF8 -Force
            Write-Host "  Created unattend.xml at $unattendPath" -ForegroundColor Green
        }
        catch {
            Write-Host "Failed to create unattend.xml: $($_.Exception.Message)" -ForegroundColor Red
            Write-Host "Continuing without /unattend parameter." -ForegroundColor Yellow
            $UnattendLanguage = $null
        }
    }

    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "RUNNING SYSPREP - FINAL STAGE" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Cyan
    if ($UnattendLanguage) {
        Write-Host "`nExecuting: Sysprep.exe /generalize /oobe /shutdown /unattend:$unattendPath" -ForegroundColor White
    } else {
        Write-Host "`nExecuting: Sysprep.exe /generalize /oobe /shutdown" -ForegroundColor White
    }
    Write-Host "`nIMPORTANT NOTES:" -ForegroundColor Yellow
    Write-Host "  - The VM will shutdown after Sysprep completes" -ForegroundColor White
    Write-Host "  - DO NOT boot this VM again!" -ForegroundColor Red
    Write-Host "  - Convert it to a Proxmox template immediately" -ForegroundColor White
    Write-Host "  - Cloudbase-init will run on first boot of deployed VMs" -ForegroundColor Cyan
    Write-Host "  - Use Proxmox cloud-init for VM customization" -ForegroundColor Cyan
    Write-Host ""

    try {
        if ($UnattendLanguage -and (Test-Path $unattendPath)) {
            & "$env:WINDIR\System32\Sysprep\Sysprep.exe" /generalize /oobe /shutdown /unattend:$unattendPath
        } else {
            & "$env:WINDIR\System32\Sysprep\Sysprep.exe" /generalize /oobe /shutdown
        }
    } catch {
        Write-Host "Sysprep failed to launch: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "CLEANUP COMPLETE - NEXT STEPS" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Cyan
    
    if ($CloudbaseAction -eq 'Enable') {
        Write-Host "`nYou are now ready for the final Sysprep stage!" -ForegroundColor Green
        Write-Host "`nRecommended actions:" -ForegroundColor Cyan
        Write-Host "  1) OPTIONAL: Reboot the VM once to verify everything works" -ForegroundColor White
        Write-Host "  2) Run the script again WITH -RunSysprep parameter:" -ForegroundColor White
        Write-Host "       .\Win11-SysprepCleanup.ps1 -CloudbaseAction Enable -RunSysprep" -ForegroundColor Yellow
        Write-Host "     OR manually run Sysprep:" -ForegroundColor White
        Write-Host "       $env:WINDIR\System32\Sysprep\Sysprep.exe /generalize /oobe /shutdown" -ForegroundColor Yellow
        Write-Host "  3) When the VM shuts down, convert it to a Proxmox template" -ForegroundColor White
        Write-Host "  4) Deploy new VMs from the template using cloud-init" -ForegroundColor White
    } else {
        Write-Host "`nCloudbase-init services have been disabled." -ForegroundColor Green
        Write-Host "`nYou can now:" -ForegroundColor Cyan
        Write-Host "  - Install your applications" -ForegroundColor White
        Write-Host "  - Apply Windows updates" -ForegroundColor White
        Write-Host "  - Configure system settings" -ForegroundColor White
        Write-Host "  - Install prerequisites" -ForegroundColor White
        Write-Host "`nWhen all installations are complete, run:" -ForegroundColor Cyan
        Write-Host "  .\Win11-SysprepCleanup.ps1 -CloudbaseAction Enable -RunSysprep" -ForegroundColor Yellow
    }
}
#endregion

Write-Host "`n=== Script finished ===" -ForegroundColor Cyan
