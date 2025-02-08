# Define the mapping of Hyper-V hosts to their iSCSI IP addresses
$iscsiIPs = @{
    "HV01" = "192.168.22.65"
    "HV02" = "192.168.22.66"
    "HV03" = "192.168.22.67"
}

# Define the correct Default Gateway (Synology NAS)
$defaultGateway = "192.168.22.253"

# Get the hostname of the current server
$hostname = $env:COMPUTERNAME

# Set the log file path
$logFilePath = [System.IO.Path]::Combine([Environment]::GetFolderPath("Desktop"), "SetISCSIIPLog.txt")
New-Item -Path $logFilePath -ItemType File -Force | Out-Null

# Function to log messages
function MyLogMessage {
    param([string]$Message)
    Write-Output $Message
    Add-Content -Path $logFilePath -Value $Message
}

# Check if the hostname exists in the mapping
if ($iscsiIPs.ContainsKey($hostname)) {
    $iscsiIP = $iscsiIPs[$hostname]
    MyLogMessage "Detected hostname: $hostname. Assigning iSCSI IP: $iscsiIP"
} else {
    MyLogMessage "Hostname $hostname is not recognized. Exiting script."
    exit
}

# Get the iSCSI network adapter (VMnet10-ISCSI)
$adapter = Get-NetAdapter | Where-Object { $_.Name -eq "VMnet10-ISCSI" }

if ($null -eq $adapter) {
    MyLogMessage "Network adapter 'VMnet10-ISCSI' not found. Exiting."
    exit
}

# Show current adapter configuration
$currentIP = (Get-NetIPAddress -InterfaceIndex $adapter.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue).IPAddress
MyLogMessage "Current IP of VMnet10-ISCSI: $currentIP"

# Set the new static IP address with Synology as Default Gateway
MyLogMessage "Setting new IP address: $iscsiIP with Default Gateway: $defaultGateway for VMnet10-ISCSI..."
New-NetIPAddress -InterfaceIndex $adapter.ifIndex -IPAddress $iscsiIP -PrefixLength 24 -DefaultGateway $defaultGateway -Confirm:$false -ErrorAction SilentlyContinue

# Verify the new configuration
$updatedIP = (Get-NetIPAddress -InterfaceIndex $adapter.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue).IPAddress
MyLogMessage "Updated IP of VMnet10-ISCSI: $updatedIP"

Write-Host "Process completed. Log file: $logFilePath"
