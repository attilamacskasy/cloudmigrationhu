# You need to run this script as an Administrator within the nested Hyper-V VM
# This script will install the Hyper-V feature and its management tools on a Windows Server 2025 machine

# The script will prompt for a restart to complete the installation
# Example: .\Install-WindowsFeature_Hyper-V.ps1

# Error Handling

# [ERROR]:      "Hyper-V cannot be installed: The processor does not have required virtualization capabilities."
# [SOLUTION]:   Enable nested virtualization on your VMware Workstation 17 / vSpeher or Hyper-V host.
                <#
                - Open VMware Workstation and select the VM you want to enable nested virtualization for.
                - Go to Edit Virtual Machine Settings.
                - Under the Processors tab:
                - Ensure "Virtualize Intel VT-x/EPT or AMD-V/RVI" is checked (as shown in the screenshot).
                - (vhv.enable = "TRUE")
                - Optionally, check "Virtualize CPU performance counters" if needed.
                - Check Hardware Compatibility: Nested virtualization requires the host machine to have hardware virtualization support.
                PS C:\Windows\system32> Get-WmiObject -Query "SELECT * FROM Win32_Processor" | Select-Object Name, VirtualizationFirmwareEnabled
                Name                                            VirtualizationFirmwareEnabled
                ----                                            -----------------------------
                AMD Ryzen 9 3900XT 12-Core Processor                                     True
                #>

# Enable Debugging Output
$DebugPreference = "Continue"

Write-Host "Starting Hyper-V installation on Windows Server 2025..." -ForegroundColor Yellow

# Check if Hyper-V is already installed
$HyperVFeature = Get-WindowsFeature -Name Hyper-V

if ($HyperVFeature.Installed) {
    Write-Host "Hyper-V is already installed on this system." -ForegroundColor Green
} else {
    Write-Host "Installing Hyper-V..." -ForegroundColor Yellow
    Install-WindowsFeature -Name Hyper-V -IncludeManagementTools -Restart:$false
}

# Install Hyper-V Management Tools
$HyperVToolsFeature = Get-WindowsFeature -Name "RSAT-Hyper-V-Tools"

if ($HyperVToolsFeature.Installed) {
    Write-Host "Hyper-V Management Tools are already installed." -ForegroundColor Green
} else {
    Write-Host "Installing Hyper-V Management Tools..." -ForegroundColor Yellow
    Install-WindowsFeature -Name RSAT-Hyper-V-Tools -Restart:$false
}

# Verify Installation
$HyperVFeature = Get-WindowsFeature -Name Hyper-V
$HyperVToolsFeature = Get-WindowsFeature -Name "RSAT-Hyper-V-Tools"

if ($HyperVFeature.Installed -and $HyperVToolsFeature.Installed) {
    Write-Host "Hyper-V and its management tools have been successfully installed." -ForegroundColor Green
} else {
    Write-Host "ERROR: Installation was not fully successful. Please check manually." -ForegroundColor Red
    exit
}

# Prompt for Restart
Write-Host "A restart is required to complete the installation." -ForegroundColor Cyan
$RestartResponse = Read-Host "Would you like to restart the server now? (Y/N)"

if ($RestartResponse -match "^[Yy]$") {
    Write-Host "Restarting the server..." -ForegroundColor Yellow
    Restart-Computer -Force
} else {
    Write-Host "Please remember to restart the server later to apply the changes." -ForegroundColor Cyan
}

# Final Debug Information
Write-Debug "Script execution completed."
