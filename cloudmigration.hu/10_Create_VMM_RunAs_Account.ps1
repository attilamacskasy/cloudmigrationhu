# example usage: .\10_Create_VMM_RunAs_Account.ps1 -VMMServerName "vmm01.cloudmigration.hu"
# or .\10_Create_VMM_RunAs_Account.ps1 -VMMServerName VMM01A

# Parameters
param (
    [Parameter(Mandatory = $true)]
    [string]$VMMServerName  # VMM Server FQDN or IP Address
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

# Prompt for Password
Write-Host "Please enter the password for the account 'CLOUDMIGRATION\administrator':"
$SecurePassword = Read-Host -AsSecureString "Password"

# Check if the Run As Account Already Exists
$RunAsAccountName = "CLOUDMIGRATION Administrator"
Write-Host "Checking if Run As Account '$RunAsAccountName' already exists..." -ForegroundColor Yellow
$ExistingRunAsAccount = Get-SCRunAsAccount | Where-Object { $_.Name -eq $RunAsAccountName }

if ($ExistingRunAsAccount) {
    Write-Host "Run As Account '$RunAsAccountName' already exists. No changes were made." -ForegroundColor Green
    exit
}

# Create the Run As Account
Write-Host "Creating Run As Account '$RunAsAccountName'..." -ForegroundColor Yellow
try {
    New-SCRunAsAccount -Name $RunAsAccountName -Description "Run As Account for CLOUDMIGRATION\administrator" `
        -Credential (New-Object System.Management.Automation.PSCredential ("CLOUDMIGRATION\administrator", $SecurePassword)) `
        -ErrorAction Stop
    Write-Host "Run As Account '$RunAsAccountName' created successfully." -ForegroundColor Green
} catch {
    Write-Host "ERROR: Failed to create Run As Account." -ForegroundColor Red
    Write-Debug "Error details: $($_.Exception.Message)"
    exit
}

# Final Debug Information
Write-Debug "Script execution completed."
