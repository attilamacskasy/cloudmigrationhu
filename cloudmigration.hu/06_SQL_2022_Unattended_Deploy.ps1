# Define Variables
$UserDesktop = [System.Environment]::GetFolderPath('Desktop')
$ISOPath = "$UserDesktop\enu_sql_server_2022_standard_edition_x64_dvd_43079f69.iso"
$MountResult = Mount-DiskImage -ImagePath $ISOPath -PassThru

if (-not $MountResult) {
    Write-Host "[ERROR] Failed to mount the ISO. Check if the file exists."; exit 1
}

$DriveLetter = ($MountResult | Get-Volume).DriveLetter + ":"
$SQLSetupPath = "$DriveLetter\setup.exe"

if (-Not (Test-Path $SQLSetupPath)) {
    Write-Host "[ERROR] SQL Server setup file not found in ISO."; exit 1
}

Write-Host "[INFO] Starting SQL Server 2022 installation..."

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
$SqlSaPassword = Get-SecurePassword

Start-Process -FilePath $SQLSetupPath -ArgumentList @(
    "/Q",                                           # Quiet mode
    "/ACTION=Install",                              # Installation action
    "/FEATURES=SQLENGINE",                          # Install Database Engine only
    "/INSTANCENAME=MSSQLSERVER",                    # Default instance
    "/SQLSVCACCOUNT=""NT AUTHORITY\SYSTEM""",       # Use system account
    "/SQLSYSADMINACCOUNTS=""Administrators""",      # Grant admin rights to local admins
    "/INSTALLSQLDATADIR=E:\",                       # Data directory
    "/SQLUSERDBDIR=E:\SQLDATA",                     # User database files
    "/SQLUSERDBLOGDIR=F:\SQLLOG",                   # User database log files
    "/SQLTEMPDBDIR=E:\TempDB",                      # TempDB data files
    "/SQLTEMPDBLOGDIR=F:\TempDB",                   # TempDB log files
    "/AGTSVCSTARTUPTYPE=Manual",                    # SQL Agent startup type
    "/SECURITYMODE=SQL",                            # Use SQL authentication
    "/SAPWD=""$SqlSaPassword""",                    # SA password
    "/IACCEPTSQLSERVERLICENSETERMS"                 # Accept SQL Server license terms
) -Wait -NoNewWindow

if ($?) {
    Write-Host "[INFO] SQL Server installation completed successfully."
} else {
    Write-Host "[ERROR] SQL Server installation encountered an issue. Check logs."
}

# Dismount the ISO
Dismount-DiskImage -ImagePath $ISOPath
Write-Host "[INFO] ISO unmounted successfully."

# Verify Installation
Write-Host "Verifying Installation..."
$SqlService = Get-Service -Name "MSSQLSERVER" -ErrorAction SilentlyContinue
if ($SqlService -and $SqlService.Status -eq "Running") {
    Write-Host "SQL Server 2022 has been installed successfully!" -ForegroundColor Green
} else {
    Write-Host "SQL Server installation failed. Please check logs at C:\Program Files\Microsoft SQL Server\150\Setup Bootstrap\Log" -ForegroundColor Red
}

# Enable Remote Connections
Write-Host "Enabling Remote Connections..."
$FirewallRuleName = "Allow SQL Server 2022"
New-NetFirewallRule -DisplayName $FirewallRuleName -Direction Inbound -Protocol TCP -LocalPort 1433 -Action Allow

Write-Host "SQL Server 2022 Deployment Completed Successfully!" -ForegroundColor Cyan
