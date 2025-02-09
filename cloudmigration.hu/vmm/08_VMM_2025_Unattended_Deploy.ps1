
# WARNING: This script is not tested and not working, it is just a placeholder for future testing.

# Very limited documentation, but it seems to be a script to install VMM 2025 unattended :)
# Not yet working an life is short to deal with this, lack of documentation and time to test it
# If you have time and energy to test it, please let me know the results
# Learn more here: https://learn.microsoft.com/en-us/system-center/vmm/install?view=sc-vmm-2025

# Define Variables
$VMMSetupPath = "C:\System Center Virtual Machine Manager\setup.exe"
$RemoteDBServer = "DB01A"
$SqlDBAdminName = "sa"  # SQL Admin username
$SqlDBAdminPassword = ""  # Placeholder for dynamic password
$VMMServiceDomain = "YourDomain"  # VMM Service domain
$VMMServiceUserName = "VMMServiceUser"  # VMM Service username
$VMMServiceUserPassword = "AnotherStrongPassword123"  # VMM Service password

# Function to Prompt for Secure SA Password
function Get-SecurePassword {
    while ($true) {
        $Password = Read-Host "Enter the SA Password (hidden)" -AsSecureString
        $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password)
        $PlainPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

        # Validation
        $isValid = $true
        $violations = @()
        
        if ($PlainPassword.Length -lt 8) { $isValid = $false; $violations += "[ERROR] Password must be at least 8 characters long." }
        if ($PlainPassword -notmatch "[A-Z]") { $isValid = $false; $violations += "[ERROR] Password must include an uppercase letter (A-Z)." }
        if ($PlainPassword -notmatch "[a-z]") { $isValid = $false; $violations += "[ERROR] Password must include a lowercase letter (a-z)." }
        if ($PlainPassword -notmatch "[0-9]") { $isValid = $false; $violations += "[ERROR] Password must include a number (0-9)." }
        if ($PlainPassword -notmatch "[!@#$%^&*()_+]") { $isValid = $false; $violations += "[ERROR] Password must include a special character (!@#$%^&*()_+)." }

        if ($isValid) {
            [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
            return $PlainPassword
        }

        Write-Host "`nYour password did not meet the following requirements:" -ForegroundColor Yellow
        foreach ($violation in $violations) { Write-Host $violation -ForegroundColor Red }
        Write-Host "`nPlease enter a valid password." -ForegroundColor Cyan
    }
}

# Get SA Password from User
$SqlDBAdminPassword = Get-SecurePassword

if (-Not (Test-Path $VMMSetupPath)) {
    Write-Host "[ERROR] VMM installation media not found. Verify the path: $VMMSetupPath"; exit 1
}

Write-Host "[INFO] Starting Virtual Machine Manager 2025 installation..."

# Install VMM with updated parameters
Start-Process -FilePath $VMMSetupPath -ArgumentList @(
"/i",                   # Action
"/server",                   # Install VMM server
    "/IAcceptSCEULA",              # Accept license terms
    "/SqlDBAdminDomain=$RemoteDBServer",        # SQL Admin domain
    "/SqlDBAdminName=$SqlDBAdminName",     # SQL Admin username
    "/SqlDBAdminPassword=$SqlDBAdminPassword", # SQL Admin password
    "/VmmServiceDomain=$VMMServiceDomain", # VMM Service domain
    "/VmmServiceUserName=$VMMServiceUserName", # VMM Service username
    "/VmmServiceUserPassword=$VMMServiceUserPassword"  # VMM Service password
) -Wait -NoNewWindow

if ($?) {
    Write-Host "[INFO] Virtual Machine Manager 2025 installation completed successfully."
} else {
    Write-Host "[ERROR] VMM installation encountered an issue. Check logs."
}
