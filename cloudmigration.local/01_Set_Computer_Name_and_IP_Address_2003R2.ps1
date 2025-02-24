param (
    [string]$ServerName
)

# Set Debug Preference (optional: you can change to "Continue" for built-in debug messages)
$DebugPreference = "Continue"

Write-Host "[DEBUG] Starting script execution..."

# Dynamically get the current user's Desktop path
$desktopPath = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::Desktop)
$configFile = Join-Path $desktopPath "cloudmigrationhu\cloudmigration.local\00_Server_Config.xml"
Write-Host "[DEBUG] Configuration file path determined as: $configFile"

# Load the XML configuration file from the Desktop
try {
    [xml]$config = Get-Content $configFile
    Write-Host "[DEBUG] Successfully loaded configuration file."
}
catch {
    Write-Host "[ERROR] Failed to load configuration file. $_"
    exit 1
}

# Get the actual current computer name from WMI
$ActualName = (Get-WmiObject -Class Win32_ComputerSystem).Name
Write-Host "[DEBUG] Actual computer name: $ActualName"

# Determine the server name to look up in the config:
if ([string]::IsNullOrEmpty($ServerName)) {
    Write-Host "[DEBUG] No server name parameter provided. Using actual computer name: $ActualName"
    $LookupName = $ActualName
}
else {
    Write-Host "[DEBUG] Using server name from parameter for lookup: $ServerName"
    $LookupName = $ServerName
}

# Find the configuration entry that matches the lookup name
$serverConfig = $config.Servers.Server | Where-Object { $_.ComputerName -eq $LookupName }
if (-not $serverConfig) {
    Write-Host "[ERROR] No configuration found for computer $LookupName in the config file."
    exit 1
}
Write-Host "[DEBUG] Found configuration for computer: $($serverConfig.ComputerName)"

# Extract configuration parameters from config file
$NewComputerName = $serverConfig.ComputerName
$IPAddress       = $serverConfig.IPAddress
$SubnetMask      = $serverConfig.SubnetMask
$DefaultGateway  = $serverConfig.DefaultGateway
Write-Host "[DEBUG] Extracted settings: NewComputerName=$NewComputerName, IPAddress=$IPAddress, SubnetMask=$SubnetMask, DefaultGateway=$DefaultGateway"

# Build DNS server array from XML nodes
$DNSServers = @()
foreach ($dns in $serverConfig.DNSServers.Server) {
    $DNSServers += $dns
}
Write-Host "[DEBUG] DNS Servers: $($DNSServers -join ', ')"

# ---------------------------
# Change Computer Name via WMI (if needed)
# ---------------------------
if ($ActualName -ne $NewComputerName) {
    Write-Host "[DEBUG] Renaming computer from $ActualName to $NewComputerName..."
    $computerSystem = Get-WmiObject -Class Win32_ComputerSystem
    $result = $computerSystem.Rename($NewComputerName)
    if ($result.ReturnValue -eq 0) {
        Write-Host "[DEBUG] Computer name changed to $NewComputerName. A reboot is required for the change to take effect."
    }
    else {
        Write-Host "[ERROR] Failed to change computer name. Error code: $($result.ReturnValue)"
    }
}
else {
    Write-Host "[DEBUG] Computer name is already set to $NewComputerName."
}

# ---------------------------
# Configure Network Settings via WMI
# ---------------------------
Write-Host "[DEBUG] Searching for the first IP-enabled network adapter..."
$nic = Get-WmiObject Win32_NetworkAdapterConfiguration -Filter "IPEnabled = True" | Select-Object -First 1

if ($null -ne $nic) {
    Write-Host "[DEBUG] Found network adapter: $($nic.Description)"
    
    # Set static IP address and subnet mask
    Write-Host "[DEBUG] Setting IP address to $IPAddress with subnet mask $SubnetMask..."
    $resultIP = $nic.EnableStatic($IPAddress, $SubnetMask)
    if ($resultIP.ReturnValue -eq 0) {
        Write-Host "[DEBUG] IP address successfully set."
    }
    else {
        Write-Host "[ERROR] Failed to set IP address. Error code: $($resultIP.ReturnValue)"
    }

    # Set default gateway
    Write-Host "[DEBUG] Setting default gateway to $DefaultGateway..."
    $resultGW = $nic.SetGateways($DefaultGateway)
    if ($resultGW.ReturnValue -eq 0) {
        Write-Host "[DEBUG] Default gateway successfully set."
    }
    else {
        Write-Host "[ERROR] Failed to set default gateway. Error code: $($resultGW.ReturnValue)"
    }

    # Set DNS servers
    Write-Host "[DEBUG] Setting DNS servers: $($DNSServers -join ', ')..."
    $resultDNS = $nic.SetDNSServerSearchOrder($DNSServers)
    if ($resultDNS.ReturnValue -eq 0) {
        Write-Host "[DEBUG] DNS servers successfully set."
    }
    else {
        Write-Host "[ERROR] Failed to set DNS servers. Error code: $($resultDNS.ReturnValue)"
    }
}
else {
    Write-Host "[ERROR] No IP-enabled network adapter found."
}

# ---------------------------
# Prompt for Restart
# ---------------------------
Write-Host "[DEBUG] Script execution completed. A reboot may be necessary for changes to take effect."
$userInput = Read-Host "Do you want to restart the computer now? (Y/N)"
if ($userInput -match "^[Yy]$") {
    Write-Host "[DEBUG] Initiating system restart..."
    shutdown /r /f /t 0
}
else {
    Write-Host "[DEBUG] Restart skipped. Please remember to restart the computer later for changes to take effect."
}
