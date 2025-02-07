# Start timer for benchmarking
$StartTime = Get-Date

# Load Configuration File
$configFile = "$PSScriptRoot\00_Server_Config.json"

if (-not (Test-Path $configFile)) {
    Write-Host "ERROR: Configuration file not found: $configFile"
    exit
}

# Read JSON File
$configRaw = Get-Content -Path $configFile -Raw
$configData = $configRaw | ConvertFrom-Json

# Validate Configuration
if (-not $configData.DomainPromotionConfig) {
    Write-Host "ERROR: DomainPromotionConfig section is missing in the configuration file."
    exit
}

# Extract Domain Promotion Parameters
$DomainConfig = $configData.DomainPromotionConfig
$DomainName = $DomainConfig.DomainName
$InstallDNS = $DomainConfig.InstallDNS
$DatabasePath = $DomainConfig.DatabasePath
$LogPath = $DomainConfig.LogPath
$SYSVOLPath = $DomainConfig.SYSVOLPath
$InstallServerRoles = $DomainConfig.InstallServerRoles

# Prompt for Directory Services Restore Mode (DSRM) password
Write-Host "Please enter the Safe Mode Administrator Password (DSRM):"
$SafeModePassword = Read-Host -AsSecureString "Safe Mode Administrator Password"

# Validate the password
if (-not $SafeModePassword) {
    Write-Host "ERROR: Password is required. Exiting script."
    exit
}

# Prompt for domain credentials
Write-Host "Please enter the credentials for a domain administrator account:"
$DomainCreds = Get-Credential

# Logging Function
function Log {
    param ([string]$Message)
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$Timestamp] $Message"
}

# Check and Install Required Server Roles
if ($InstallServerRoles) {
    Log "Checking and installing required server roles..."
    $Roles = Get-WindowsFeature | Where-Object { $_.Name -eq "AD-Domain-Services" -or $_.Name -eq "DNS" }
    foreach ($Role in $Roles) {
        if (-not $Role.Installed) {
            Log "Installing role: $($Role.Name)..."
            Install-WindowsFeature -Name $Role.Name -IncludeManagementTools -Verbose
        } else {
            Log "Role already installed: $($Role.Name)"
        }
    }
}

# Start DC Promotion for Additional Domain Controller
Log "Starting DC promotion for additional domain controller using ADDSDeployment module..."
try {
    Install-ADDSDomainController `
        -Credential $DomainCreds `
        -DomainName $DomainName `
        -SafeModeAdministratorPassword $SafeModePassword `
        -InstallDNS:$InstallDNS `
        -DatabasePath $DatabasePath `
        -LogPath $LogPath `
        -SYSVOLPath $SYSVOLPath `
        -Force `
        -NoRebootOnCompletion
    Log "Additional Domain Controller promotion completed successfully."
} catch {
    Log "Error during DC promotion: $($_.Exception.Message)"
    exit
}

# Calculate and Display Benchmark Time
$EndTime = Get-Date
$Duration = $EndTime - $StartTime
Log "Script completed successfully in $($Duration.TotalSeconds) seconds."
