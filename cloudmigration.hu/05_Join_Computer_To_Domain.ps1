# Enable Debugging Output
$DebugPreference = "Continue"

# Load Configuration File
$configFile = "$PSScriptRoot\00_Server_Config.json"
Write-Debug "Loading configuration file from: $configFile"

if (-not (Test-Path $configFile)) {
    Write-Host "ERROR: Configuration file not found: $configFile" -ForegroundColor Red
    exit
}

# Read JSON File
try {
    Write-Debug "Reading configuration file..."
    $configRaw = Get-Content -Path $configFile -Raw
    $configData = $configRaw | ConvertFrom-Json
    Write-Debug "Configuration file successfully parsed."
    Write-Debug "Parsed configuration: $($configData | ConvertTo-Json -Depth 10)"
} catch {
    Write-Host "ERROR: Failed to parse configuration file. Ensure it is a valid JSON file." -ForegroundColor Red
    Write-Debug "Error details: $($_.Exception.Message)"
    exit
}

# Extract Domain Configuration
try {
    $DomainName = $configData.DomainPromotionConfig.DomainName
    $NetBIOSName = $configData.DomainPromotionConfig.NetBIOSName
    $AdminUser = $configData.DomainPromotionConfig.AdministratorUsername

    if (-not $DomainName -or -not $NetBIOSName -or -not $AdminUser) {
        Write-Host "ERROR: Missing domain configuration details in JSON file." -ForegroundColor Red
        exit
    }

    # Construct the domain admin username
    $FullAdminUser = "$NetBIOSName\$AdminUser"
    
    Write-Debug "Extracted Domain Configuration:"
    Write-Debug "Domain Name: $DomainName"
    Write-Debug "NetBIOS Name: $NetBIOSName"
    Write-Debug "Administrator Username: $AdminUser"
    Write-Debug "Full Admin User: $FullAdminUser"

} catch {
    Write-Host "ERROR: Failed to extract domain configuration." -ForegroundColor Red
    Write-Debug "Error details: $($_.Exception.Message)"
    exit
}

# Prompt for Domain Admin Password
Write-Host "Please enter the password for the domain administrator ($FullAdminUser):"
$DomainPassword = Read-Host -AsSecureString "Domain Admin Password"

# Validate the password
if (-not $DomainPassword) {
    Write-Host "ERROR: Password is required. Exiting script." -ForegroundColor Red
    exit
}

# Convert Credentials to Secure Format
$Credential = New-Object System.Management.Automation.PSCredential ($FullAdminUser, $DomainPassword)

# Join Computer to the Domain
Write-Host "Joining computer to domain: $DomainName..." -ForegroundColor Yellow
try {
    Add-Computer -DomainName $DomainName -Credential $Credential -Force
    Write-Host "Computer successfully joined to the domain." -ForegroundColor Green
} catch {
    Write-Host "ERROR: Failed to join the computer to the domain." -ForegroundColor Red
    Write-Debug "Error details: $($_.Exception.Message)"
    exit
}

# Ask User Before Restarting
Write-Host "A restart is required to complete the domain join process." -ForegroundColor Cyan
$restartResponse = Read-Host "Would you like to restart the computer now? (Y/N)"

if ($restartResponse -match "^[Yy]$") {
    Write-Host "Restarting the computer..." -ForegroundColor Yellow
    Restart-Computer -Force
} else {
    Write-Host "Please remember to restart the computer later to apply the changes." -ForegroundColor Cyan
}

# Final Debug Information
Write-Debug "Script execution completed."
