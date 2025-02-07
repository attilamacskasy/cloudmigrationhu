# Parameter Declaration
param (
    [Parameter(Mandatory = $true)]
    [string]$ServerName
)

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

# Validate Server Name
Write-Debug "ServerName provided: $ServerName"

try {
    $serverConfig = $configData.ServerSpecificConfig | Where-Object { $_.ServerName -eq $ServerName }
    if (-not $serverConfig) {
        Write-Host "ERROR: Server '$ServerName' not found in configuration file." -ForegroundColor Red
        exit
    }
    Write-Debug "Server configuration found: $($serverConfig | ConvertTo-Json -Depth 10)"
} catch {
    Write-Host "ERROR: Failed to find server configuration in JSON file." -ForegroundColor Red
    Write-Debug "Error details: $($_.Exception.Message)"
    exit
}

# Function to Convert Subnet Mask to Prefix Length
function Convert-SubnetMaskToPrefixLength {
    param ([string]$SubnetMask)

    Write-Debug "Converting Subnet Mask '$SubnetMask' to Prefix Length..."
    
    # Convert each octet of the subnet mask to binary and join them into one string
    $binaryMask = $SubnetMask.Split('.') | ForEach-Object { [Convert]::ToString([int]$_, 2).PadLeft(8, '0') }
    $binaryString = $binaryMask -join ''

    # Count the number of '1's in the binary string to determine the prefix length
    $prefixLength = ($binaryString -replace '0', '').Length

    Write-Debug "Binary representation of Subnet Mask: $binaryString"
    Write-Debug "Calculated Prefix Length: $prefixLength"

    return $prefixLength
}

# Extract Configuration
try {
    $ComputerName = $serverConfig.ComputerName
    $IPAddress = $serverConfig.IPAddress
    $SubnetMask = $serverConfig.SubnetMask
    $DefaultGateway = $serverConfig.DefaultGateway
    $DNSServers = $serverConfig.DNSServers

    # Convert Subnet Mask to Prefix Length
    $PrefixLength = Convert-SubnetMaskToPrefixLength -SubnetMask $SubnetMask
    Write-Debug "Extracted configuration: ComputerName=$ComputerName, IPAddress=$IPAddress, SubnetMask=$SubnetMask, PrefixLength=$PrefixLength, DefaultGateway=$DefaultGateway, DNSServers=$DNSServers"
} catch {
    Write-Host "ERROR: Failed to extract server configuration." -ForegroundColor Red
    Write-Debug "Error details: $($_.Exception.Message)"
    exit
}

# Set Computer Name
Write-Host "Setting computer name to $ComputerName..." -ForegroundColor Yellow
try {
    Rename-Computer -NewName $ComputerName -Force -PassThru
    Write-Debug "Computer name set to $ComputerName."
    Write-Host "A restart is required for the computer name change to take effect." -ForegroundColor Cyan
} catch {
    Write-Host "ERROR: Failed to set computer name." -ForegroundColor Red
    Write-Debug "Error details: $($_.Exception.Message)"
    exit
}

# Configure Network Adapter
Write-Host "Configuring network adapter..." -ForegroundColor Yellow
try {
    $adapter = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
    if (-not $adapter) {
        Write-Host "ERROR: No active network adapters found." -ForegroundColor Red
        exit
    }

    Write-Debug "Active network adapter: $($adapter.Name)"
    Write-Host "Setting IP address to $IPAddress, SubnetMask to $SubnetMask (PrefixLength=$PrefixLength), and DefaultGateway to $DefaultGateway..." -ForegroundColor Yellow
    New-NetIPAddress -IPAddress $IPAddress -PrefixLength $PrefixLength -DefaultGateway $DefaultGateway -InterfaceIndex $adapter.ifIndex
    Write-Debug "Network adapter configured successfully."
} catch {
    Write-Host "ERROR: Failed to configure network adapter." -ForegroundColor Red
    Write-Debug "Error details: $($_.Exception.Message)"
    exit
}

# Set DNS Servers
Write-Host "Configuring DNS servers: $DNSServers..." -ForegroundColor Yellow
try {
    Set-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -ServerAddresses $DNSServers
    Write-Debug "DNS servers configured successfully."
} catch {
    Write-Host "ERROR: Failed to configure DNS servers." -ForegroundColor Red
    Write-Debug "Error details: $($_.Exception.Message)"
    exit
}

# Output Summary
Write-Host "Configuration applied. Summary:"
$summary = @{
    ComputerName   = $ComputerName
    IPAddress      = $IPAddress
    SubnetMask     = $SubnetMask
    PrefixLength   = $PrefixLength
    DefaultGateway = $DefaultGateway
    DNSServers     = $DNSServers
}
$summary | Format-Table -AutoSize

# Ask the user to restart
Write-Host "Configuration completed successfully. A manual restart is recommended to apply changes." -ForegroundColor Green
$restartResponse = Read-Host "Would you like to restart the computer now? (Y/N)"

if ($restartResponse -match "^[Yy]$") {
    Write-Host "Restarting the computer..." -ForegroundColor Yellow
    Restart-Computer
} else {
    Write-Host "Please remember to restart the computer later to apply the changes." -ForegroundColor Cyan
}

# Final Debug Information
Write-Debug "Script execution completed."
