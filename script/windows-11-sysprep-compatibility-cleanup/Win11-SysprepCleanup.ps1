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
    .\Win11-SysprepCleanup.ps1 -CloudbaseAction Enable -RunSysprep -UnattendLanguage hu-HU
    
    RECOMMENDED: Always use -UnattendLanguage (hu-HU or en-US) to:
    - Generate C:\Windows\System32\Sysprep\unattend.xml (you can review before Sysprep runs)
    - Automatically skip all OOBE screens (language, EULA, privacy, account setup)
    - Create local "localuser" administrator account automatically
    - Set proper timezone and regional settings
    
    This script executes the following steps when run with -RunSysprep:
    
    STEP 1: Cloudbase-Init Management
    ----------------------------------
    - Re-enables cloudbase-init services (required for Proxmox cloud-init)
    - Services will start automatically on first boot after template deployment
    
    STEP 2: BitLocker Cleanup
    --------------------------
    - Checks if BitLocker is enabled on C: drive
    - Disables BitLocker if enabled (required for Sysprep)
    - Waits for full decryption to complete
    
    STEP 3: AppX Package Removal
    -----------------------------
    - Removes Sysprep-blocking AppX packages (language packs, Xbox, etc.)
    - Removes provisioned packages (prevents reinstall for new users)
    - Optional: Deep scan for user-only packages (use -ScanUserPackages switch)
    - Displays summary: removed/skipped/failed counts
    
    STEP 4: Unattend.xml Generation (if -UnattendLanguage specified)
    -----------------------------------------------------------------
    - Creates C:\Windows\System32\Sysprep\unattend.xml with your language choice
    - File includes comprehensive comments explaining each setting
    - You can review/modify this file before Sysprep runs
    
    STEP 5: Sysprep Execution
    --------------------------
    - Runs: C:\Windows\System32\Sysprep\Sysprep.exe /generalize /oobe /shutdown
    - With unattend.xml: adds /unattend:C:\Windows\System32\Sysprep\unattend.xml
    - VM will shutdown automatically when complete
    
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
        HIGHLY RECOMMENDED! Generates C:\Windows\System32\Sysprep\unattend.xml
        with comprehensive settings to automate OOBE and skip all manual prompts.
        
        When used with -RunSysprep, the script will:
        1. Create unattend.xml with your chosen language/region settings
        2. You can review the generated XML file before Sysprep runs
        3. Run Sysprep with /unattend parameter to use this configuration
        
        The generated unattend.xml will:
        - Skip all OOBE wizard screens (language, EULA, privacy, account setup)
        - Create local administrator account "localuser" with password "P@ssw0rd!"
        - Set keyboard layout and timezone based on language choice
        - Configure privacy settings to recommended baseline
        
        Supported values:
          - en-US  : English (United States) / UTC timezone
          - hu-HU  : Hungarian / Central Europe Standard Time
        
        Without this parameter, Windows will show all OOBE screens on first boot,
        which defeats the purpose of an automated template deployment!
    
    -ScanUserPackages <Switch>
        When supplied, detects and removes AppX packages installed for a single user only
        (These scans can take several minutes; disabled by default.)
        
    USAGE EXAMPLES:
    ---------------
    # Check cloudbase-init service status
    .\Win11-SysprepCleanup.ps1 -CloudbaseAction Check
    
    # Disable cloudbase-init before installing apps
    .\Win11-SysprepCleanup.ps1 -CloudbaseAction Disable
    
    # RECOMMENDED: Enable cloudbase-init and run Sysprep with unattend.xml (Hungarian)
    .\Win11-SysprepCleanup.ps1 -CloudbaseAction Enable -RunSysprep -UnattendLanguage hu-HU
    
    # RECOMMENDED: Enable cloudbase-init and run Sysprep with unattend.xml (English)
    .\Win11-SysprepCleanup.ps1 -CloudbaseAction Enable -RunSysprep -UnattendLanguage en-US
    
    # Enable cloudbase-init and run Sysprep WITHOUT unattend.xml (not recommended)
    # This will require manual OOBE configuration on first boot
    .\Win11-SysprepCleanup.ps1 -CloudbaseAction Enable -RunSysprep
    
    # Just cleanup and enable cloudbase-init without running Sysprep
    # Use this if you want to run Sysprep manually later
    .\Win11-SysprepCleanup.ps1 -CloudbaseAction Enable

    # Run with deep user-only AppX package scan (takes longer, more thorough)
    .\Win11-SysprepCleanup.ps1 -CloudbaseAction Enable -ScanUserPackages -RunSysprep -UnattendLanguage hu-HU
    
    # Manual Sysprep (if you didn't use -RunSysprep):
    # WITH unattend.xml (recommended - review/edit C:\Windows\System32\Sysprep\unattend.xml first):
    C:\Windows\System32\Sysprep\Sysprep.exe /generalize /oobe /shutdown /unattend:C:\Windows\System32\Sysprep\unattend.xml
    
    # WITHOUT unattend.xml (will show all OOBE screens on first boot):
    C:\Windows\System32\Sysprep\Sysprep.exe /generalize /oobe /shutdown
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

#region Generate unattend.xml if language is specified
if ($UnattendLanguage) {
    $unattendPath = Join-Path $env:WINDIR 'System32\Sysprep\unattend.xml'
    
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "GENERATING UNATTEND.XML" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Language: $UnattendLanguage" -ForegroundColor White
    
    $inputLocale  = $UnattendLanguage
    $systemLocale = $UnattendLanguage
    $userLocale   = $UnattendLanguage
    $uiLanguage   = $UnattendLanguage

    # Determine timezone based on language
    $timeZone = if ($UnattendLanguage -eq 'hu-HU') { 'Central Europe Standard Time' } else { 'UTC' }

    $unattendContent = @"
<?xml version="1.0" encoding="utf-8"?>
<!--
  Unattend file for Windows 11 template in Proxmox
  - Skips the entire OOBE wizard (user, region, privacy, telemetry screens)
  - Creates a local Administrator user "localuser"
  - Uses $UnattendLanguage locale and keyboard
  - Time zone: $timeZone
  - Designed to be used together with Cloudbase-Init + Proxmox Cloud-Init
-->

<unattend xmlns="urn:schemas-microsoft-com:unattend">

  <!-- ============================================================
       PASS: generalize
       ============================================================
       Runs when Sysprep generalize is executed.
       Here we only set SkipRearm so we can rebuild images multiple
       times without hitting activation rearm limits.
       ============================================================ -->
  <settings pass="generalize">
    <component name="Microsoft-Windows-Security-SPP"
               processorArchitecture="amd64"
               publicKeyToken="31bf3856ad364e35"
               language="neutral"
               versionScope="nonSxS">
      <!--
        SkipRearm = 1 means Sysprep will not decrease the activation
        rearm counter. This is useful for golden images in labs.
      -->
      <SkipRearm>1</SkipRearm>
    </component>
  </settings>

  <!-- ============================================================
       PASS: oobeSystem
       ============================================================
       Runs during the first boot after Sysprep generalize.
       We use this pass to:
         - set language, region, keyboard
         - completely skip the OOBE UI (including privacy pages)
         - create a local administrator account "localuser"
       ============================================================ -->
  <settings pass="oobeSystem">

    <!-- ==========================================================
         LANGUAGE / REGION / KEYBOARD SETTINGS
         ==========================================================
         All set to $UnattendLanguage.
         This should prevent the region / keyboard selection screens.
         ========================================================== -->
    <component name="Microsoft-Windows-International-Core"
               processorArchitecture="amd64"
               publicKeyToken="31bf3856ad364e35"
               language="neutral"
               versionScope="nonSxS">
      <!-- Keyboard layout used during OOBE and for the system -->
      <InputLocale>$inputLocale</InputLocale>

      <!-- System locale (non-Unicode programs, etc.) -->
      <SystemLocale>$systemLocale</SystemLocale>

      <!-- UI language (display language) -->
      <UILanguage>$uiLanguage</UILanguage>

      <!-- Fallback UI language (used if main is not available) -->
      <UILanguageFallback>$uiLanguage</UILanguageFallback>

      <!-- User locale (number/date formats, etc.) -->
      <UserLocale>$userLocale</UserLocale>
    </component>

    <!-- ==========================================================
         SHELL / OOBE BEHAVIOR
         ==========================================================
         This block:
           - hides almost all OOBE screens
           - skips user + machine OOBE
           - auto-creates a local administrator account
           - sets time zone, owner, organization
         ========================================================== -->
    <component name="Microsoft-Windows-Shell-Setup"
               processorArchitecture="amd64"
               publicKeyToken="31bf3856ad364e35"
               language="neutral"
               versionScope="nonSxS">

      <!--
        OOBE configuration:
        These options together are responsible for hiding:
          - EULA page
          - MS account and online account screens
          - wireless setup
          - privacy / telemetry choices
          - region / keyboard / "how will this device be used" prompts
      -->
      <OOBE>
        <!-- Do not show the license agreement page -->
        <HideEULAPage>true</HideEULAPage>

        <!-- Hide OEM registration (not relevant in a VM lab) -->
        <HideOEMRegistrationScreen>true</HideOEMRegistrationScreen>

        <!-- Do not offer Microsoft account / online account setup -->
        <HideOnlineAccountScreens>true</HideOnlineAccountScreens>

        <!-- We do not need Wi-Fi setup in Proxmox VMs -->
        <HideWirelessSetupInOOBE>true</HideWirelessSetupInOOBE>

        <!-- Treat this as a work (corporate) device, not a home PC -->
        <NetworkLocation>Work</NetworkLocation>

        <!-- "Protect your PC" default: 1 = recommended settings -->
        <ProtectYourPC>1</ProtectYourPC>

        <!--
          The two keys below are the most important:
          They instruct Windows to skip the entire OOBE flow
          (including privacy / diagnostics / tracking pages).
        -->
        <SkipUserOOBE>true</SkipUserOOBE>
        <SkipMachineOOBE>true</SkipMachineOOBE>
      </OOBE>

      <!--
        LOCAL USER CREATION
        ===================
        We create one local Administrator account:
          username:  localuser
          password:  P@ssw0rd!
        This prevents Windows from asking for:
          - local account name
          - password
          - security questions
        You can log on as "localuser" the first time if needed.
        In production you may want to change this username/password.
      -->
      <UserAccounts>
        <LocalAccounts>
          <LocalAccount xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State"
                        wcm:action="add">
            <!-- Local username that will be created during OOBE -->
            <Name>localuser</Name>

            <!-- Add the account to the local Administrators group -->
            <Group>Administrators</Group>

            <!-- Plain text password for the local account -->
            <Password>
              <Value>P@ssw0rd!</Value>
              <PlainText>true</PlainText>
            </Password>
          </LocalAccount>
        </LocalAccounts>
      </UserAccounts>

      <!-- Registration fields (optional, purely cosmetic) -->
      <RegisteredOwner>Administrator</RegisteredOwner>
      <RegisteredOrganization>Proxmox</RegisteredOrganization>

      <!--
        Time zone setting.
        Hungarian locale uses Central Europe Standard Time,
        English (US) uses UTC for broad compatibility.
      -->
      <TimeZone>$timeZone</TimeZone>

      <!--
        NOTE:
        We intentionally do NOT set ComputerName here.
        Proxmox + Cloudbase-Init + Cloud-Init will set the hostname
        automatically based on the VM name and Cloud-Init metadata.
      -->

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
        Write-Host "`nSuccessfully created unattend.xml at:" -ForegroundColor Green
        Write-Host "  $unattendPath" -ForegroundColor Cyan
        Write-Host "`nYou can now:" -ForegroundColor Yellow
        Write-Host "  1. Review/edit the generated XML file" -ForegroundColor White
        Write-Host "  2. Run Sysprep manually with: " -ForegroundColor White
        Write-Host "     C:\Windows\System32\Sysprep\Sysprep.exe /generalize /oobe /shutdown /unattend:$unattendPath" -ForegroundColor Cyan
        Write-Host "  3. Or re-run this script with -RunSysprep to execute Sysprep automatically" -ForegroundColor White
    }
    catch {
        Write-Host "`nFailed to create unattend.xml: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "You may need to run this script as Administrator." -ForegroundColor Yellow
    }
}
#endregion

#region Optionally run Sysprep
if ($RunSysprep) {
    $unattendPath = Join-Path $env:WINDIR 'System32\Sysprep\unattend.xml'
    
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
        Write-Host "  2) Run the script again WITH -RunSysprep and -UnattendLanguage:" -ForegroundColor White
        Write-Host "`n     RECOMMENDED (Hungarian with unattend.xml):" -ForegroundColor Yellow
        Write-Host "       .\Win11-SysprepCleanup.ps1 -CloudbaseAction Enable -RunSysprep -UnattendLanguage hu-HU" -ForegroundColor Cyan
        Write-Host "`n     RECOMMENDED (English with unattend.xml):" -ForegroundColor Yellow
        Write-Host "       .\Win11-SysprepCleanup.ps1 -CloudbaseAction Enable -RunSysprep -UnattendLanguage en-US" -ForegroundColor Cyan
        Write-Host "`n     OR run Sysprep manually after generating unattend.xml:" -ForegroundColor White
        Write-Host "       First, generate unattend.xml by running this script with -UnattendLanguage (without -RunSysprep)" -ForegroundColor DarkGray
        Write-Host "       Review/edit: C:\Windows\System32\Sysprep\unattend.xml" -ForegroundColor DarkGray
        Write-Host "       Then run: C:\Windows\System32\Sysprep\Sysprep.exe /generalize /oobe /shutdown /unattend:C:\Windows\System32\Sysprep\unattend.xml" -ForegroundColor Cyan
        Write-Host "`n  3) When the VM shuts down, convert it to a Proxmox template" -ForegroundColor White
        Write-Host "  4) Deploy new VMs from the template using cloud-init" -ForegroundColor White
        Write-Host "`n  Why use -UnattendLanguage?" -ForegroundColor Yellow
        Write-Host "    - Skips ALL OOBE screens automatically (no manual input needed)" -ForegroundColor White
        Write-Host "    - Creates local 'localuser' admin account for first login" -ForegroundColor White
        Write-Host "    - Sets proper timezone and language/keyboard settings" -ForegroundColor White
        Write-Host "    - You can review the generated XML before Sysprep runs" -ForegroundColor White
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
