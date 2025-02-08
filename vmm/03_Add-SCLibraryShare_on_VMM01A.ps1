
# this script will add a library share to VMM Server
# The library share is a network share that contains resources such as virtual hard disks, ISO images, and scripts that can be used to create and deploy virtual machines.
# The library share is added to the VMM server so that the resources can be accessed and used by the VMM server and its managed hosts.
# The script will prompt for credentials to connect to the VMM server and add the library share to the VMM server.
# The script will check if the library share is already added to the VMM server and add it if it is not already added.
# The script will display the final verification of the VMM library configuration after adding the library share.
# The script will exit with an error if it fails to add the library share to the VMM server.
# Learn more here: https://learn.microsoft.com/en-us/powershell/module/virtualmachinemanager/add-sclibraryshare?view=systemcenter-ps-2025

# Define Parameters 
$libraryServerName =    "FS01A.cloudmigration.hu"
$libraryShareName =     "VMM_Library"
$librarySharePath =     "\\$libraryServerName\$libraryShareName"
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

# Add the Library Share to VMM
Write-Host "`n[INFO] Checking if VMM Library Share is already added to VMM..." -ForegroundColor Yellow
$existingLibraryShare = Get-SCLibraryShare | Where-Object { $_.SharePath -eq $librarySharePath }

if ($existingLibraryShare) {
    Write-Host "[OK] Library Share already exists in VMM: $librarySharePath" -ForegroundColor Green
} else {
    Write-Host "[INFO] Adding Library Share to VMM: $librarySharePath" -ForegroundColor Cyan
    try {
        $creds2 = New-Object System.Management.Automation.PSCredential ("CLOUDMIGRATION\administrator", (ConvertTo-SecureString "cmlab.2199L" -AsPlainText -Force))
        Add-SCLibraryShare -SharePath $librarySharePath -Description "VMM Library for FS01A" -VMMServer $vmmServer -Credential $creds2 -RunAsynchronously -ErrorAction Stop
        Write-Host "[SUCCESS] VMM Library Share successfully added!" -ForegroundColor Green
    } catch {
        Write-Host "[ERROR] Failed to add VMM Library Share. $_" -ForegroundColor Red
        exit 1
    }
}

# Final Verification
Write-Host "`n[INFO] Final Verification of VMM Library Configuration..." -ForegroundColor Cyan
Get-SCLibraryServer | Format-Table Name, ComputerName -AutoSize
Get-SCLibraryShare | Format-Table Name, SharePath -AutoSize

Write-Host "`n[SUCCESS] VMM Library Setup is Complete!" -ForegroundColor Green
