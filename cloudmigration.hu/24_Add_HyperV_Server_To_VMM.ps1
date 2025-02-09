# example usage: .\11_Add_HyperV_Server_To_VMM.ps1 -VMMServerName "vmm01a.cloudmigration.hu" -HyperVHostName "hv01.cloudmigration.hu" -RunAsAccount "CLOUDMIGRATION Administrator"
# or # example usage: .\11_Add_HyperV_Server_To_VMM.ps1 -VMMServerName VMM01A -HyperVHostName HV01 -RunAsAccount "CLOUDMIGRATION Administrator"

# Parameters
param (
    [Parameter(Mandatory = $true)]
    [string]$VMMServerName,  # VMM Server FQDN or IP Address
    [Parameter(Mandatory = $true)]
    [string]$HyperVHostName, # Hyper-V Server FQDN or IP Address
    [Parameter(Mandatory = $true)]
    [string]$RunAsAccount    # VMM Run As Account Name
)

# Enable Debugging Output
$DebugPreference = "Continue"

# Import the Virtual Machine Manager Module
Write-Host "Importing VMM module..." -ForegroundColor Yellow
try {
    Import-Module VirtualMachineManager -ErrorAction Stop
    Write-Debug "VMM module imported successfully."
} catch {
    Write-Host "ERROR: Failed to import the VMM module. Ensure it is installed." -ForegroundColor Red
    Write-Debug "Error details: $($_.Exception.Message)"
    exit
}

# Connect to the VMM Server
Write-Host "Connecting to VMM Server: $VMMServerName..." -ForegroundColor Yellow
try {
    $VMMServer = Get-SCVMMServer -ComputerName $VMMServerName -ErrorAction Stop
    Write-Debug "Connected to VMM Server: $($VMMServer.Name)"
} catch {
    Write-Host "ERROR: Unable to connect to the VMM Server. Check the server name and network connectivity." -ForegroundColor Red
    Write-Debug "Error details: $($_.Exception.Message)"
    exit
}

# Check if the Hyper-V Host is Already Added
Write-Host "Checking if the Hyper-V server '$HyperVHostName' is already in VMM..." -ForegroundColor Yellow
$ExistingHost = Get-SCVMHost -VMMServer $VMMServer | Where-Object { $_.Name -eq $HyperVHostName }

if ($ExistingHost) {
    Write-Host "The Hyper-V server '$HyperVHostName' is already managed by VMM." -ForegroundColor Green
    exit
}

# Add the Hyper-V Host to VMM
Write-Host "Adding Hyper-V server '$HyperVHostName' to VMM..." -ForegroundColor Yellow
try {
    Add-SCVMHost -VMMServer $VMMServer -ComputerName $HyperVHostName -Credential (Get-SCRunAsAccount -Name $RunAsAccount) -ErrorAction Stop
    Write-Host "Hyper-V server '$HyperVHostName' added successfully to VMM." -ForegroundColor Green
} catch {
    Write-Host "ERROR: Failed to add the Hyper-V server to VMM." -ForegroundColor Red
    Write-Debug "Error details: $($_.Exception.Message)"
    exit
}

# Final Debug Information
Write-Debug "Script execution completed."
