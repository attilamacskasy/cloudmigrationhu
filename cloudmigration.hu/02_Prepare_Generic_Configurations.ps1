# This script works on both Windows Server 2022 and Windows Server 2025.
# Not yet tested on Windows 2003 server in our retro lab, haha :-)

# Load Global Configuration and Apply Generic Settings to the Server

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
if (-not $configData.GlobalConfig) {
    Write-Host "ERROR: GlobalConfig section is missing in the configuration file."
    exit
}

# Extract Global Settings
$GlobalConfig = $configData.GlobalConfig
$TimeZone = $GlobalConfig.TimeZone
$NTPServer = $GlobalConfig.NTPServer
$EnableRemoteDesktop = $GlobalConfig.EnableRemoteDesktop
$DisableFirewall = $GlobalConfig.DisableFirewall
$IEConfig = $GlobalConfig.IEEnhancedSecurityConfiguration

# Set Time Zone
if ($TimeZone) {
    Write-Host "Setting time zone to $TimeZone..."
    tzutil /s $TimeZone
} else {
    Write-Host "Time zone not specified in GlobalConfig. Skipping..."
}

# Configure NTP Server
if ($NTPServer) {
    Write-Host "Configuring NTP server to $NTPServer..."
    w32tm /config /manualpeerlist:$NTPServer /syncfromflags:manual /reliable:YES /update
    Restart-Service w32time
    Write-Host "Waiting for the Windows Time service to stop..."
    Start-Sleep -Seconds 5

    # Verify NTP Configuration
    Write-Host "Verifying NTP server configuration..."
    $ntpConfig = w32tm /query /configuration | Select-String -Pattern "NtpServer"
    Write-Host "Configured NTP Server: $($ntpConfig -replace '.*NtpServer: (.*)', '$1')"
} else {
    Write-Host "NTP server not specified in GlobalConfig. Skipping..."
}

# Allow Remote Desktop with Network Level Authentication
if ($EnableRemoteDesktop) {
    Write-Host "Enabling Remote Desktop with Network Level Authentication..."
    Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server\' -Name "fDenyTSConnections" -Value 0
    Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
} else {
    Write-Host "Remote Desktop configuration skipped."
}

# Disable Windows Defender Firewall for Domain, Private, and Public
if ($DisableFirewall) {
    Write-Host "Disabling Windows Defender Firewall for all profiles..."
    Set-NetFirewallProfile -Profile Domain,Private,Public -Enabled False
} else {
    Write-Host "Firewall configuration skipped."
}

# Disable IE Enhanced Security Configuration
function Disable-IEESC {
    Write-Host "Disabling Internet Explorer Enhanced Security Configuration (ESC)..."
    $AdminKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}"
    $UserKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}"
    try {
        Set-ItemProperty -Path $AdminKey -Name "IsInstalled" -Value 0
        Set-ItemProperty -Path $UserKey -Name "IsInstalled" -Value 0
        Stop-Process -Name Explorer -Force
        Write-Host "IE ESC has been disabled for both Administrators and Users."
    } catch {
        Write-Host "Error: Unable to disable IE ESC. $($_.Exception.Message)"
    }
}

if ($IEConfig) {
    Disable-IEESC
} else {
    Write-Host "IE Enhanced Security Configuration skipped."
}

Write-Host "Generic configuration completed successfully."
