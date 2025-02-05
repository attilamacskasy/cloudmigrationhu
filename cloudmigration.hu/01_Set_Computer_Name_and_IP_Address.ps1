
# start with this in case you get error in new Windows install: Set-ExecutionPolicy Bypass -Scope Process -Force

param (
    [string]$ServerName
)

# Validate Input
if (-not $ServerName) {
    Write-Host "ERROR: Please specify a server name. Usage: .\01_Set_Computer_Name_and_IP_Address.ps1 -ServerName DC01" -ForegroundColor Red
    exit
}

# Load Configuration File
$configFile = ".\00_Server_Config.json"

if (-not (Test-Path $configFile)) {
    Write-Host "ERROR: Configuration file not found: $configFile" -ForegroundColor Red
    exit
}

# Parse JSON Configuration
$configData = Get-Content $configFile | ConvertFrom-Json

# Validate Server Configuration
if (-not $configData.$ServerName) {
    Write-Host "ERROR: Server '$ServerName' not found in configuration file." -ForegroundColor Red
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
    Write-Host "No active network adapter found. Please check your connection." -ForegroundColor Red
    exit
}

# Rename Computer
Write-Host "Renaming computer to $NewComputerName..."
Rename-Computer -NewName $NewComputerName -Force

# Configure Static IP Address
Write-Host "Configuring static IP address..."
New-NetIPAddress -InterfaceIndex $NetAdapter.ifIndex -IPAddress $IPAddress -PrefixLength 24 -DefaultGateway $Gateway -Confirm:$false

# Set DNS Servers
Write-Host "Setting DNS servers..."
Set-DnsClientServerAddress -InterfaceIndex $NetAdapter.ifIndex -ServerAddresses ($PrimaryDNS, $SecondaryDNS)

# Output Summary of Changes
Write-Host "`nConfiguration Summary for $NewComputerName"
$Summary = [PSCustomObject]@{
    "Computer Name" = $NewComputerName
    "IP Address" = $IPAddress
    "Subnet Mask" = $SubnetMask
    "Default Gateway" = $Gateway
    "Primary DNS" = $PrimaryDNS
    "Secondary DNS" = $SecondaryDNS
    "Network Adapter" = $NetAdapter.Name
}
$Summary | Format-Table -AutoSize

# Prompt User Before Restart
$UserInput = Read-Host "`n🔁 Do you want to restart now? (Y/N)"
if ($UserInput -eq "Y" -or $UserInput -eq "y") {
    Write-Host "Restarting system..."
    Restart-Computer -Force
} else {
    Write-Host "Setup complete! Please restart manually to apply changes."
}

# usage example: .\setup-dc.ps1 -ServerName DC01

