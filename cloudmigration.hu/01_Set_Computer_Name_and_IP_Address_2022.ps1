# start with this in case you get error in new Windows install: Set-ExecutionPolicy Bypass -Scope Process -Force

param (
    [string]$ServerName
)

# Validate Input
if (-not $ServerName) {
    Write-Host "ERROR: Please specify a server name. Usage: .\01_Set_Computer_Name_and_IP_Address.ps1 -ServerName DC01"
    exit
}

# Load Configuration File
$configFile = "$PSScriptRoot\00_Server_Config.json"

if (-not (Test-Path $configFile)) {
    Write-Host "ERROR: Configuration file not found: $configFile"
    exit
}

# Read JSON File (Compatible with PowerShell 5.1)
$configRaw = Get-Content -Path $configFile -Raw
$configData = $configRaw | ConvertFrom-Json

# Validate Server Configuration
if (-not $configData.PSObject.Properties[$ServerName]) {
    Write-Host "ERROR: Server '$ServerName' not found in configuration file."
    exit
}

# Extract Settings
$ServerConfig = $configData.$ServerName
$NewComputerName = $ServerConfig.ComputerName
$IPAddress = $ServerConfig.IPAddress
$SubnetMask = $ServerConfig.SubnetMask
$Gateway = $ServerConfig.Gateway
$PrimaryDNS = $ServerConfig.PrimaryDNS
$SecondaryDNS = $ServerConfig.SecondaryDNS

# Get the active network adapter
$NetAdapter = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }

# Ensure the network adapter is found
if (-not $NetAdapter) {
    Write-Host "ERROR: No active network adapter found. Please check your connection."
    exit
}

# Rename Computer
Write-Host "Renaming computer to $NewComputerName..."
Rename-Computer -NewName $NewComputerName -Force

# Configure Static IP Address (Compatible with PowerShell 5.1)
Write-Host "Configuring static IP address..."
$InterfaceName = $NetAdapter.Name
& netsh interface ipv4 set address name="$InterfaceName" static $IPAddress $SubnetMask $Gateway

# Set DNS Servers (Compatible with PowerShell 5.1)
Write-Host "Setting DNS servers..."
& netsh interface ipv4 set dnsservers name="$InterfaceName" source=static address=$PrimaryDNS validate=no
& netsh interface ipv4 add dnsservers name="$InterfaceName" address=$SecondaryDNS index=2

# Output Summary of Changes
Write-Host "`nConfiguration Summary for $NewComputerName"
Write-Host "-----------------------------------"
Write-Host "Computer Name  : $NewComputerName"
Write-Host "IP Address     : $IPAddress"
Write-Host "Subnet Mask    : $SubnetMask"
Write-Host "Default Gateway: $Gateway"
Write-Host "Primary DNS    : $PrimaryDNS"
Write-Host "Secondary DNS  : $SecondaryDNS"
Write-Host "Network Adapter: $NetAdapter.Name"
Write-Host "-----------------------------------"

# Prompt User Before Restart
$UserInput = Read-Host "`nDo you want to restart now? (Y/N)"
if ($UserInput -eq "Y" -or $UserInput -eq "y") {
    Write-Host "Restarting system..."
    Restart-Computer -Force
} else {
    Write-Host "Setup complete! Please restart manually to apply changes."
}

# usage example: .\01_Set_Computer_Name_and_IP_Address.ps1 -ServerName DC01

