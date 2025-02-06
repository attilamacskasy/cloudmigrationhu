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
if ($IEConfig) {
    Write-Host "Disabling IE Enhanced Security Configuration..."
    $Administrators = $IEConfig.Administrators
    $Users = $IEConfig.Users
    if ($Administrators -eq "Off") {
        Set-ItemProperty -Path 'HKLM:\Software\Microsoft\Active Setup\Installed Components\{781EF3BA-773E-4B42-AC36-50F17C8DA3B3}' -Name "IsInstalled" -Value 0
    }
    if ($Users -eq "Off") {
        Set-ItemProperty -Path 'HKLM:\Software\Microsoft\Active Setup\Installed Components\{5CB30B9D-CDD8-4FD8-AF90-BB076A59EC97}' -Name "IsInstalled" -Value 0
    }
} else {
    Write-Host "IE Enhanced Security Configuration skipped."
}

Write-Host "Generic configuration completed successfully."
