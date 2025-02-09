# Script to create an external virtual switch on Hyper-V
# when running script remotely from RDP session there will be a short disconnect when the switch is created because the network adapter is reconfigured.
# This script assumes that the network adapter is already configured on the host machine.
# The script will check if the virtual switch already exists and create it if it does not.
# The script will output the status of the operation to the console.
# The script will exit with a status code of 1 if the network adapter is not found.
# The script will exit with a status code of 0 if the virtual switch is successfully created.

# Suggested Name:
# "vSwitch-External-MGMT"

# Naming Breakdown:
# vSwitch: Prefix to indicate it’s a Hyper-V virtual switch.
# External: Denotes the switch type (External, Internal, or Private).
# MGMT: Identifies the purpose of the switch (e.g., Management traffic in this case).

# https://learn.microsoft.com/en-us/powershell/module/hyper-v/new-vmswitch?view=windowsserver2025-ps

# New-VMSwitch
#    [-CimSession <CimSession[]>]
#    [-ComputerName <String[]>]
#    [-Credential <PSCredential[]>]
#    [-Name] <String>
#    [-AllowManagementOS <Boolean>]
#    -NetAdapterName <String[]>
#    [-Notes <String>]
#    [-MinimumBandwidthMode <VMSwitchBandwidthMode>]
#    [-EnableIov <Boolean>]
#    [-EnablePacketDirect <Boolean>]
#    [-EnableEmbeddedTeaming <Boolean>]
#    [-WhatIf]
#    [-Confirm]
#    [<CommonParameters>]

# Detect hostname
$hostname = $env:COMPUTERNAME
Write-Host "Running on Host: $hostname"

# Define virtual switch name and network adapter
$VirtualSwitchName = "vSwitch-External-MGMNT"
$NetworkAdapterName = "VMNet0-MGMNT"

# Get the network adapter
$networkAdapter = Get-NetAdapter | Where-Object { $_.Name -eq $NetworkAdapterName }

if ($null -eq $networkAdapter) {
    Write-Host "Error: Network adapter '$NetworkAdapterName' not found on $hostname." -ForegroundColor Red
    exit 1
}

# Check if the virtual switch already exists
$existingSwitch = Get-VMSwitch | Where-Object { $_.Name -eq $VirtualSwitchName }

if ($null -ne $existingSwitch) {
    Write-Host "Virtual switch '$VirtualSwitchName' already exists on $hostname." -ForegroundColor Yellow
} else {
    # Create the external virtual switch
    try {
        New-VMSwitch -Name $VirtualSwitchName -NetAdapterName $NetworkAdapterName -AllowManagementOS $true
        Write-Host "Successfully created external virtual switch '$VirtualSwitchName' bound to '$NetworkAdapterName' on $hostname." -ForegroundColor Green
    } catch {
        Write-Host "Failed to create the virtual switch: $_" -ForegroundColor Red
    }
}
