# Parameters
$LogicalNetworkName = "Management-LN"
$NetworkSiteName = "Management-NS"
$LogicalSwitchName = "Management-LS"
$UplinkPortProfileName = "Management-UPP"
$VMNetworkName = "Management-VMNET"
$HostGroup = Get-SCVMHostGroup -Name "All Hosts" # Adjust if needed
$MyHost = Get-SCVMHost -ComputerName "HV01" # Replace with your host name
$VirtualSwitchName = "vSwitch-External-MGMNT" # Existing Hyper-V switch name
$Subnet = "172.22.22.0/24"

# Step 1: Create Logical Network
Write-Host "Step 1: Checking for existing Logical Network '$LogicalNetworkName'..."
$LogicalNetwork = Get-SCLogicalNetwork -Name $LogicalNetworkName -ErrorAction SilentlyContinue
if ($LogicalNetwork) {
    Write-Host "Logical Network '$LogicalNetworkName' already exists. Skipping creation."
} else {
    $Confirm = Read-Host "Logical Network '$LogicalNetworkName' does not exist. Create it? (Y/N)"
    if ($Confirm -eq "Y") {
        Write-Host "Creating Logical Network '$LogicalNetworkName'..."
        $LogicalNetwork = New-SCLogicalNetwork -Name $LogicalNetworkName `
            -VMMServer "VMM01A" `
            -Description "Logical Network for Management Traffic"
        Write-Host "Logical Network '$LogicalNetworkName' created successfully."
    } else {
        Write-Host "Skipping Logical Network creation."
        Exit
    }
}

# Step 2: Create Network Site
Write-Host "Step 2: Checking for existing Network Site '$NetworkSiteName'..."
$NetworkSite = Get-SCLogicalNetworkDefinition -LogicalNetwork $LogicalNetwork -ErrorAction SilentlyContinue | Where-Object { $_.Name -eq $NetworkSiteName }
if ($NetworkSite) {
    Write-Host "Network Site '$NetworkSiteName' already exists. Skipping creation."
} else {
    $Confirm = Read-Host "Network Site '$NetworkSiteName' does not exist. Create it? (Y/N)"
    if ($Confirm -eq "Y") {
        Write-Host "Creating Network Site '$NetworkSiteName'..."
        $NetworkSite = New-SCLogicalNetworkDefinition `
            -LogicalNetwork $LogicalNetwork `
            -Name $NetworkSiteName `
            -VMHostGroup $HostGroup `
            -SubnetVLan $Subnet
        Write-Host "Network Site '$NetworkSiteName' created successfully."
    } else {
        Write-Host "Skipping Network Site creation."
        Exit
    }
}

# Step 3: Create Logical Switch
Write-Host "Step 3: Checking for existing Logical Switch '$LogicalSwitchName'..."
$LogicalSwitch = Get-SCLogicalSwitch -Name $LogicalSwitchName -ErrorAction SilentlyContinue
if ($LogicalSwitch) {
    Write-Host "Logical Switch '$LogicalSwitchName' already exists. Skipping creation."
} else {
    $Confirm = Read-Host "Logical Switch '$LogicalSwitchName' does not exist. Create it? (Y/N)"
    if ($Confirm -eq "Y") {
        Write-Host "Creating Logical Switch '$LogicalSwitchName'..."
        $LogicalSwitch = New-SCLogicalSwitch -Name $LogicalSwitchName -Description "Logical Switch for Management Traffic"
        Write-Host "Logical Switch '$LogicalSwitchName' created successfully."
    } else {
        Write-Host "Skipping Logical Switch creation."
        Exit
    }
}

# Step 4: Create Uplink Port Profile
Write-Host "Step 4: Checking for existing Uplink Port Profile '$UplinkPortProfileName'..."
$UplinkPortProfile = Get-SCUplinkPortProfile -Name $UplinkPortProfileName -ErrorAction SilentlyContinue
if ($UplinkPortProfile) {
    Write-Host "Uplink Port Profile '$UplinkPortProfileName' already exists. Skipping creation."
} else {
    $Confirm = Read-Host "Uplink Port Profile '$UplinkPortProfileName' does not exist. Create it? (Y/N)"
    if ($Confirm -eq "Y") {
        Write-Host "Creating Uplink Port Profile '$UplinkPortProfileName'..."
        $UplinkPortProfile = New-SCUplinkPortProfile -Name $UplinkPortProfileName `
            -LogicalSwitch $LogicalSwitch `
            -ConnectionMode "Team" `
            -LogicalNetwork $LogicalNetwork `
            -VMHostGroup $HostGroup
        Write-Host "Uplink Port Profile '$UplinkPortProfileName' created successfully."
    } else {
        Write-Host "Skipping Uplink Port Profile creation."
        Exit
    }
}

# Step 5: Associate Logical Switch with Hyper-V Virtual Switch
Write-Host "Step 5: Associating Logical Switch '$LogicalSwitchName' with Hyper-V Virtual Switch '$VirtualSwitchName'..."
$HostVirtualSwitch = Get-SCVirtualNetwork -VMHost $MyHost | Where-Object { $_.Name -eq $VirtualSwitchName }
if ($HostVirtualSwitch) {
    $LogicalSwitchAssociation = Get-SCLogicalSwitchAssociation -LogicalSwitch $LogicalSwitch -VMHost $MyHost -ErrorAction SilentlyContinue
    if (-not $LogicalSwitchAssociation) {
        Add-SCVMHostNetworkAdapter -VMHost $MyHost `
            -LogicalSwitch $LogicalSwitch `
            -VirtualNetwork $HostVirtualSwitch `
            -UplinkPortProfile $UplinkPortProfile `
            -EnableTeaming $false
        Write-Host "Logical Switch '$LogicalSwitchName' successfully associated with Virtual Switch '$VirtualSwitchName'."
    } else {
        Write-Host "Logical Switch '$LogicalSwitchName' is already associated with Virtual Switch '$VirtualSwitchName'. Skipping association."
    }
} else {
    Write-Error "Hyper-V Virtual Switch '$VirtualSwitchName' not found on host '$MyHost'. Ensure the switch exists before proceeding."
    Exit
}

# Step 6: Create VM Network
Write-Host "Step 6: Checking for existing VM Network '$VMNetworkName'..."
$VMNetwork = Get-SCVMNetwork -Name $VMNetworkName -ErrorAction SilentlyContinue
if ($VMNetwork) {
    Write-Host "VM Network '$VMNetworkName' already exists. Skipping creation."
} else {
    $Confirm = Read-Host "VM Network '$VMNetworkName' does not exist. Create it? (Y/N)"
    if ($Confirm -eq "Y") {
        Write-Host "Creating VM Network '$VMNetworkName'..."
        $VMNetwork = New-SCVMNetwork `
            -Name $VMNetworkName `
            -LogicalNetwork $LogicalNetwork `
            -IsolationType "None" `
            -Description "VM Network for Management Traffic"
        Write-Host "VM Network '$VMNetworkName' created successfully."
    } else {
        Write-Host "Skipping VM Network creation."
        Exit
    }
}

# Final Verification
Write-Host "Configuration steps completed. Verify the following in the VMM GUI:"
Write-Host "1. Logical Network: '$LogicalNetworkName'"
Write-Host "2. Network Site: '$NetworkSiteName'"
Write-Host "3. Logical Switch: '$LogicalSwitchName' with Uplink Port Profile '$UplinkPortProfileName'"
Write-Host "4. VM Network: '$VMNetworkName' associated with Logical Network '$LogicalNetworkName'"
Write-Host "Check your configuration in the VMM Fabric and Networking views."
