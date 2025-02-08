# Define variables
$ubuntuIsoUrl = "https://releases.ubuntu.com/noble/ubuntu-24.04.1-live-server-amd64.iso"  # Update this URL to the latest Ubuntu Server ISO
$isoFileName = "ubuntu-24.04.1-live-server-amd64.iso"  # Update this to match the ISO file name
$userDesktop = [System.Environment]::GetFolderPath("Desktop")  # Get current user's Desktop path
$downloadPath = "$userDesktop\$isoFileName"
$libraryServer = "FS01A"
$libraryShare = "\\$libraryServer\VMM_Library"  # Update this to your actual library share path
$librarySharePath = "$libraryShare\$isoFileName"
$username = "CLOUDMIGRATION\administrator" # Change if needed


# Check if the file already exists
if (Test-Path $downloadPath) {
    Write-Host "Ubuntu Server ISO already exists on Desktop. Skipping download."
    # Get the Desktop path of the current user
    $userDesktop = [System.Environment]::GetFolderPath("Desktop")
    # List files containing "ubuntu" in the filename (case-insensitive)
    Get-ChildItem -Path $userDesktop -Filter "*ubuntu*" -File
} else {
    # Use BITS to download the Ubuntu ISO (faster than Invoke-WebRequest)
    Write-Host "Downloading Ubuntu Server ISO to $downloadPath..."
    Start-BitsTransfer -Source $ubuntuIsoUrl -Destination $downloadPath
    Write-Host "Download completed."
}

# Import the Virtual Machine Manager module
Import-Module VirtualMachineManager

# Prompt for Credentials
$Creds = $null
while ($null -eq $Creds) {
    $password = Read-Host "Enter password for $username" -AsSecureString
    $Creds = New-Object System.Management.Automation.PSCredential ($username, $password)
    
    if ($Creds -isnot [System.Management.Automation.PSCredential]) {
        Write-Host "[ERROR] Invalid credential format. Please enter valid credentials." -ForegroundColor Red
        $Creds = $null
    }
}

# Add the library server to VMM (if not already added)
# Add-SCLibraryServer -ComputerName $libraryServer -Credential $Creds

# Add the library share to VMM (if not already added)
# Add-SCLibraryShare -Path $libraryShare -Description "VMM Library Share on FS01A"

# Copy the ISO to the VMM library share
Write-Host "Copying the ISO to the VMM library share..."
Copy-Item -Path $downloadPath -Destination $librarySharePath -Force
Write-Host "ISO copied successfully to VMM Library."

# Refresh the library share to recognize the new ISO
#$libraryShareObject = Get-SCLibraryShare -Path $libraryShare
#Refresh-SCLibraryShare -LibraryShare $libraryShareObject
# https://learn.microsoft.com/en-us/powershell/module/virtualmachinemanager/read-sclibraryshare?view=systemcenter-ps-2025
Write-Host "Refresh VMM Library manually. Ubuntu Server ISO is now available as a template."

# dir "%USERPROFILE%\Desktop\*ubuntu*" /A:-D /B
