# Disable IPv6 for all network adapters on Windows Server 2025
# Requires Administrator privileges

# Log file location
$logFilePath = [System.IO.Path]::Combine([Environment]::GetFolderPath("Desktop"), "DisableIPv6Log.txt")
New-Item -Path $logFilePath -ItemType File -Force | Out-Null

# Function to log messages
function MyLogMessage {
    param([string]$Message)
    Write-Output $Message
    Add-Content -Path $logFilePath -Value $Message
}

# Function to get detailed adapter information
function Get-AdapterInfo {
    Get-NetAdapter | Where-Object { $_.Status -eq "Up" } | ForEach-Object {
        $ipConfig = Get-NetIPAddress -InterfaceIndex $_.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue
        [PSCustomObject]@{
            Name       = $_.Name
            LinkSpeed  = $_.LinkSpeed
            IPAddress  = ($ipConfig.IPAddress -join ', ')  # Join multiple IPs if present
            InterfaceIndex = $_.InterfaceIndex
        }
    }
}

# Get all active network adapters
$adapters = Get-AdapterInfo

# Show current adapter configuration
MyLogMessage "=== Current Network Adapter Configuration ==="
$adapters | Format-Table Name, LinkSpeed, IPAddress, InterfaceIndex -AutoSize
$adapters | ForEach-Object {
    MyLogMessage "Adapter: $($_.Name), Link Speed: $($_.LinkSpeed), IP: $($_.IPAddress), InterfaceIndex: $($_.InterfaceIndex)"
}

# Prompt user before disabling IPv6
$confirmation = Read-Host "Do you want to disable IPv6 for all adapters? (yes/no)"
if ($confirmation -ne "yes") {
    MyLogMessage "User chose not to disable IPv6. Exiting."
    exit
}

# Disable IPv6 for each adapter
foreach ($adapter in $adapters) {
    MyLogMessage "Disabling IPv6 on $($adapter.Name) (InterfaceIndex: $($adapter.InterfaceIndex))..."
    Disable-NetAdapterBinding -Name $adapter.Name -ComponentID ms_tcpip6 -Confirm:$false
}

# Verify IPv6 status after changes
MyLogMessage "`n=== Updated Network Adapter Configuration ==="
$adapters = Get-AdapterInfo  # Refresh adapter list
$adapters | Format-Table Name, LinkSpeed, IPAddress, InterfaceIndex -AutoSize
$adapters | ForEach-Object {
    $ipv6Status = Get-NetAdapterBinding -Name $_.Name -ComponentID ms_tcpip6
    MyLogMessage "Adapter: $($_.Name), Link Speed: $($_.LinkSpeed), IP: $($_.IPAddress), IPv6 Enabled: $($ipv6Status.Enabled)"
}

MyLogMessage "`nIPv6 has been disabled for all network adapters."
Write-Host "Process completed. Log file: $logFilePath"
