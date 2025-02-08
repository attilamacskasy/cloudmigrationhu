# PowerShell script to list all disks with size, filesystem, allocation unit size, free space, % used, and drive letter.

# Function to get Allocation Unit Size
function Get-AllocationUnitSize {
    param ($DriveLetter)
    if ($null -ne $DriveLetter) {
        $fsInfo = fsutil fsinfo ntfsinfo $DriveLetter 2>$null
        if ($fsInfo -match "Bytes Per Cluster\s+:\s+(\d+)") {
            return [int]$matches[1]
        }
    }
    return "N/A"
}

# Get all online disks
$disks = Get-Disk | Where-Object { $_.OperationalStatus -eq "Online" }

# Get all volumes, including those without drive letters
$volumes = Get-Volume | Where-Object { $_.FileSystem -ne $null }

# Get detailed disk information
$diskInfo = $disks | ForEach-Object {
    # Ensure disk has partitions before running Get-Partition
    $partitions = Get-Partition -DiskNumber $_.Number -ErrorAction SilentlyContinue
    if ($partitions -eq $null) { $partitions = @() } # Ensure it's an array even if empty

    # Get all volumes related to this disk
    $diskVolumes = $volumes | Where-Object { $partitions.DriveLetter -contains $_.DriveLetter }

    # Get a list of file systems (handling multiple partitions per disk)
    $fileSystems = ($diskVolumes | Select-Object -ExpandProperty FileSystem -Unique) -join ", "
    if ([string]::IsNullOrEmpty($fileSystems)) { $fileSystems = "No Filesystem" }

    # Get Drive Letter (only show first drive letter if multiple exist)
    $driveLetter = ($diskVolumes | Select-Object -ExpandProperty DriveLetter -Unique) -join ", "
    if ([string]::IsNullOrEmpty($driveLetter)) { $driveLetter = "N/A" }

    # Get total free and used space (handling multiple volumes)
    $totalSize = $_.Size
    $totalFreeSpace = ($diskVolumes | Measure-Object -Property SizeRemaining -Sum).Sum
    $totalUsedSpace = $totalSize - $totalFreeSpace

    # Handle cases where free space is null
    if ($totalFreeSpace -eq $null) { $totalFreeSpace = 0 }
    if ($totalUsedSpace -eq $null) { $totalUsedSpace = 0 }

    # Calculate percentage used
    $percentUsed = if ($totalSize -gt 0) { [math]::Round(($totalUsedSpace / $totalSize) * 100, 2) } else { "N/A" }

    # Retrieve allocation unit size (from first available drive letter)
    $allocationUnit = "N/A"
    if ($diskVolumes.Count -gt 0 -and $diskVolumes[0].DriveLetter -ne $null) {
        $allocationUnit = Get-AllocationUnitSize $diskVolumes[0].DriveLetter
    }

    [PSCustomObject]@{
        "Disk Number"         = $_.Number
        "Size (GB)"           = [math]::Round($_.Size / 1GB, 2)
        "FileSystem"          = $fileSystems
        "Allocation Unit Size" = $allocationUnit
        "Drive Letter"        = $driveLetter
        "Free Space (GB)"     = [math]::Round($totalFreeSpace / 1GB, 2)
        "Used Space (GB)"     = [math]::Round($totalUsedSpace / 1GB, 2)
        "% Used"              = $percentUsed
    }
}

# Display results
$diskInfo | Format-Table -AutoSize
