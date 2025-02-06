param (
    [string]$driveLetter = "J"  # Default drive letter is J
)

# Enable debug messages
$DebugPreference = "Continue"

# Set network path and credentials
$networkPath = "\\172.22.22.108\cloudmigration.hu"
$username = "attila"

# Prompt for password with custom message
Write-Debug "Prompting user for password..."
$passwordPrompt = "Enter password for user '$username' to access '$networkPath'"
$password = Read-Host -AsSecureString $passwordPrompt

# Create a PSCredential object with the username and password
Write-Debug "Creating credential object..."
$credential = New-Object System.Management.Automation.PSCredential($username, $password)

# Attempt to map the network drive
Write-Debug "Attempting to map network location: $networkPath to drive $driveLetter"

try {
    # Use the New-PSDrive cmdlet to map the network location to the specified drive letter
    New-PSDrive -Name $driveLetter -PSProvider FileSystem -Root $networkPath -Credential $credential -Persist
    Write-Debug "Successfully mounted the network location as drive $driveLetter."
} catch {
    Write-Debug "Failed to mount the network location. Error: $_"
}

# Verify the network location is accessible
if (Test-Path "${driveLetter}:") {
    Write-Debug "Network drive $driveLetter is accessible."
} else {
    Write-Debug "Network drive $driveLetter is not accessible."
}
