# Define adapter mappings from the Markdown table
$adapterMappings = @(
    @{ IPRange = "172.22.22.0/24"; VMnetID = "VMnet0"; Acronym = "MGMNT" },
    @{ IPRange = "192.168.1.0/24"; VMnetID = "VMnet1"; Acronym = "LVMIG" },
    @{ IPRange = "192.168.2.0/24"; VMnetID = "VMnet2"; Acronym = "CLNET" },
    @{ IPRange = "192.168.22.0/24"; VMnetID = "VMnet10"; Acronym = "ISTOR" },
    @{ IPRange = "192.168.3.0/24"; VMnetID = "VMnet3"; Acronym = "VMINT" },
    @{ IPRange = "192.168.0.0/24"; VMnetID = "VMnet8"; Acronym = "VMEXT" },
    @{ IPRange = "192.168.4.0/24"; VMnetID = "VMnet4"; Acronym = "BACKP" }
)

# Set the log file path
$logFilePath = [System.IO.Path]::Combine([Environment]::GetFolderPath("Desktop"), "NetworkAdapterRenameLog.txt")
New-Item -Path $logFilePath -ItemType File -Force | Out-Null

# Function to log messages
function MyLogMessage {
    param([string]$Message)
    Write-Output $Message
    Add-Content -Path $logFilePath -Value $Message
}

# Function to check if an IP is in a CIDR range
function Test-IPInRange {
    param([string]$IPAddress, [string]$CIDR)

    # Split CIDR into base IP and prefix length
    $split = $CIDR -split "/"
    $baseIP = [System.Net.IPAddress]::Parse($split[0])
    $prefix = [int]$split[1]

    # Convert IP addresses to byte arrays
    $ipBytes = [System.Net.IPAddress]::Parse($IPAddress).GetAddressBytes()
    $baseBytes = $baseIP.GetAddressBytes()

    # Compute subnet mask
    $mask = ([math]::Pow(2, 32) - [math]::Pow(2, 32 - $prefix)) -as [uint32]
    $maskBytes = [BitConverter]::GetBytes($mask)
    [Array]::Reverse($maskBytes)  # Reverse byte order for comparison

    # Compare the network parts
    for ($i = 0; $i -lt 4; $i++) {
        if (($ipBytes[$i] -band $maskBytes[$i]) -ne ($baseBytes[$i] -band $maskBytes[$i])) {
            return $false
        }
    }
    return $true
}

# Function to get all Ethernet adapters and their IPv4 addresses only
function Get-NetworkAdapters {
    Get-NetAdapter -Physical | ForEach-Object {
        $ipConfig = Get-NetIPAddress -InterfaceIndex $_.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue
        [PSCustomObject]@{
            Name      = $_.Name
            IPAddress = ($ipConfig.IPAddress -join ',')
            Interface = $_
        }
    } | Where-Object { $null -ne $_.IPAddress }
}

# Initial listing of adapters
MyLogMessage "=== Current Network Adapters ==="
$adapters = Get-NetworkAdapters
$adapters | Format-Table Name, IPAddress

# Identify adapters to rename
MyLogMessage "`nIdentifying network adapters to rename..."
$adaptersToRename = @()

foreach ($adapter in $adapters) {
    foreach ($mapping in $adapterMappings) {
        $ipAddresses = $adapter.IPAddress -split ","
        foreach ($ip in $ipAddresses) {
            MyLogMessage "Checking IP $ip against range $($mapping.IPRange)..."
            if (Test-IPInRange -IPAddress $ip -CIDR $mapping.IPRange) {
                $newName = "$($mapping.VMnetID)-$($mapping.Acronym)"
                MyLogMessage "Match found: Adapter $($adapter.Name) -> New Name: $newName"
                
                # Add to rename list
                $adaptersToRename += [PSCustomObject]@{
                    CurrentName = $adapter.Name
                    NewName     = $newName
                    IPAddress   = $ip
                }
            }
        }
    }
}

if ($adaptersToRename.Count -eq 0) {
    MyLogMessage "No adapters matched the IP ranges. Exiting."
    exit
}

# Display adapters to rename
MyLogMessage "`nAdapters to be renamed:"
$adaptersToRename | Format-Table CurrentName, NewName, IPAddress -AutoSize

# Prompt user
$confirmation = Read-Host "Do you want to proceed with renaming the adapters? (yes/no)"
if ($confirmation -ne "yes") {
    MyLogMessage "User chose not to rename adapters. Exiting."
    exit
}

# Rename the adapters
foreach ($entry in $adaptersToRename) {
    MyLogMessage "Renaming adapter: $($entry.CurrentName) -> $($entry.NewName)"
    Rename-NetAdapter -Name $entry.CurrentName -NewName $entry.NewName -Confirm:$false
}

# Final listing of adapters
MyLogMessage "`n=== Final Network Adapter Configuration ==="
$finalAdapters = Get-NetworkAdapters
$finalAdapters | Format-Table Name, IPAddress -AutoSize

# Log final adapters
$finalAdapters | ForEach-Object {
    MyLogMessage "Adapter: $($_.Name), IP Address: $($_.IPAddress)"
}

MyLogMessage "`nProcess completed. All changes logged to $logFilePath"
Write-Host "Process completed. Log file: $logFilePath"
