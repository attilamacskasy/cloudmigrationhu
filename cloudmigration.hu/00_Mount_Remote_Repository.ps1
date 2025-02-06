param (
    [string]$PreferredDriveLetter = "J" # Default preferred drive letter is J
)

# Enable debug messages
$DebugPreference = "Continue"

# Set network path and credentials
$NetworkPath = "\\172.22.22.108\cloudmigrationhu"
$Username = "attila"

# Prompt for password with custom message
Write-Debug "Prompting user for password..."
$PasswordPrompt = "Enter password for user '$Username' to access '$NetworkPath'"
$Password = Read-Host -AsSecureString $PasswordPrompt

# Function to find the next available drive letter
function Get-AvailableDriveLetter {
    $UsedLetters = Get-PSDrive -PSProvider FileSystem | Select-Object -ExpandProperty Name
    $AllLetters = 'D'..'Z' # Typically, A:, B:, C: are reserved
    $AvailableLetters = $AllLetters | Where-Object { $_ -notin $UsedLetters }
    return $AvailableLetters
}

# Check if the preferred drive letter is available
$UsedDriveLetters = Get-PSDrive -PSProvider FileSystem | Select-Object -ExpandProperty Name
if ($UsedDriveLetters -contains $PreferredDriveLetter) {
    Write-Debug "Preferred drive letter $PreferredDriveLetter is already in use. Selecting an available drive letter..."
    $AvailableDriveLetters = Get-AvailableDriveLetter
    if ($AvailableDriveLetters.Count -eq 0) {
        Write-Error "No available drive letters found."
        exit
    } else {
        $DriveLetter = $AvailableDriveLetters[0]
        Write-Debug "Selected drive letter $DriveLetter."
    }
} else {
    $DriveLetter = $PreferredDriveLetter
    Write-Debug "Preferred drive letter $DriveLetter is available."
}

# Convert secure password to plain text for net use
$PlainTextPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password)
)

# Build the net use command with proper escaping for the colon
$MaskedPassword = "***"
$netUseCommandMasked = "net use ${DriveLetter}: $NetworkPath /user:$Username $MaskedPassword /persistent:yes"
$netUseCommand = "net use ${DriveLetter}: $NetworkPath /user:$Username $PlainTextPassword /persistent:yes"

# Output the command with masked password
Write-Debug "Executing: $netUseCommandMasked"

# Attempt to map the network drive using net use
try {
    Invoke-Expression $netUseCommand

    # Verify the drive was successfully mapped
    if (Test-Path "${DriveLetter}:\") {
        Write-Output "Successfully mapped $NetworkPath to drive ${DriveLetter}:"
    } else {
        Write-Error "Failed to verify mapping of $NetworkPath to drive ${DriveLetter}:"
    }
} catch {
    Write-Error "Failed to map network drive: $_"
}

# Cleanup plain text password from memory
[System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR(
    [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password)
)
