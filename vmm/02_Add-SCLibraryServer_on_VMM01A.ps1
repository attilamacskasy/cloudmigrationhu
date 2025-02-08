# this script will add FS01A as a Library Server in VMM
# The script will prompt for credentials to connect to the VMM server and add the library share to the VMM server.
# The script will check if FS01A is already a Library Server and add it if it is not already added.
# The script will display the final verification of the VMM library configuration after adding FS01A as a Library Server.
# The script will exit with an error if it fails to add FS01A as a Library Server.

# Learn more here: https://learn.microsoft.com/en-us/powershell/module/virtualmachinemanager/add-sclibraryserver?view=systemcenter-ps-2025

# Define Parameters  
$libraryServerName =    "FS01A.cloudmigration.hu"
$vmmServerName =        "localhost"  # Change if running remotely
$username =             "CLOUDMIGRATION\administrator" # Change if needed

# Import the VMM module
Import-Module VirtualMachineManager

# Connect to VMM
Write-Host "`n[INFO] Connecting to VMM Server: $vmmServerName" -ForegroundColor Cyan
$vmmServer = Get-SCVMMServer -ComputerName $vmmServerName -ErrorAction Stop

if (-Not $vmmServer) {
    Write-Host "[ERROR] Failed to connect to VMM Server: $vmmServerName" -ForegroundColor Red
    exit 1
}

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

# Register FS01A as a Library Server
Write-Host "`n[INFO] Checking if FS01A is already a Library Server..." -ForegroundColor Yellow
$existingLibraryServer = Get-SCLibraryServer | Where-Object { $_.ComputerName -eq $libraryServerName }

if ($existingLibraryServer) {
    Write-Host "[OK] FS01A is already registered as a Library Server in VMM." -ForegroundColor Green
} else {
    Write-Host "[INFO] Adding FS01A as a Library Server in VMM..." -ForegroundColor Cyan
    try {
        Add-SCLibraryServer -ComputerName $libraryServerName -VMMServer $vmmServer -Credential $Creds -RunAsynchronously -ErrorAction Stop
        Write-Host "[SUCCESS] FS01A has been successfully registered as a Library Server!" -ForegroundColor Green
    } catch {
        Write-Host "[ERROR] Failed to add FS01A as a Library Server. $_" -ForegroundColor Red
        exit 1
    }
}

# Final Verification
Write-Host "`n[INFO] Final Verification of VMM Library Configuration..." -ForegroundColor Cyan
Get-SCLibraryServer | Format-Table Name, ComputerName -AutoSize

Write-Host "`n[SUCCESS] VMM Library Setup is not yet complete, run 03_Add-SCLibraryShare_on_VMM01A.ps1 to complete!" -ForegroundColor Cyan
