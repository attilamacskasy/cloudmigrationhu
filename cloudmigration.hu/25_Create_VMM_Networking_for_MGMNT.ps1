# This script is designed to work with System Center Virtual Machine Manager (VMM) 2025 and Windows Server 2025 Hyper-V hosts.  
# I might reach out to my friends at Microsoft—those who still care about VMM and aren't entirely consumed by Azure and AI advancements. :)  

# Configuring networking in VMM has always been a complex task, especially when dealing with Logical Networks, Network Sites, Logical Switches, and VM Networks.  
# This script aims to streamline and automate the creation of these critical networking components for a dedicated management network in VMM.  

# Note: The uplink port profile creation is still a work in progress. If your VMM client crashes after applying the configuration, don’t panic—just roll back (delete) the changes,  
# manually using VMM UI, fix any missing parts, and retry.  

# As time permits, I'll update this script to include uplink port profile creation and refine its reliability. Stay tuned!

# [BELOW IS MY EFFORT TO DO THIS ON VMM GUI - AND VIEW SCRIPT BUTTON - BASELINE TO FIX AUTOMATION SCRIPT] 

# https://learn.microsoft.com/en-us/system-center/vmm/manage-networks?view=sc-vmm-2025

# Here's what you'll typically do to set up networking in the VMM fabric:

# 1. Set up logical networks: Create logical networks that map to your physical networks. You can create network sites that map to network sites in your physical network. For example, IP subnets, VLNS, or subnet/VLAN pairs. Then if you're not using DHCP, you create IP address pools for the network sites that exist within your physical networks.
<# 
    $logicalNetwork = New-SCLogicalNetwork -Name "Management-LN" -LogicalNetworkDefinitionIsolation $false -EnableNetworkVirtualization $false -UseGRE $false -IsPVLAN $false -Description "Set up logical networks: Create logical networks that map to your physical networks. You can create network sites that map to network sites in your physical network. For example, IP subnets, VLNS, or subnet/VLAN pairs. Then if you`'re not using DHCP, you create IP address pools for the network sites that exist within your physical networks."

    New-SCVMNetwork -Name "Management-LN" -IsolationType "NoIsolation" -LogicalNetwork $logicalNetwork
    $allHostGroups = @()
    $allHostGroups += Get-SCVMHostGroup -ID "0e3ba228-a059-46be-aa41-2f5cf0f4b96e"
    $allSubnetVlan = @()
    $allSubnetVlan += New-SCSubnetVLan -Subnet "172.22.22.0/24" -VLanID 1

    $logicalNetworkDefinition = New-SCLogicalNetworkDefinition -Name "Management-LN_0" -LogicalNetwork $logicalNetwork -VMHostGroup $allHostGroups -SubnetVLan $allSubnetVlan -RunAsynchronously

    # Network Routes
    $allNetworkRoutes = @()

    # Gateways
    $allGateways = @()
    $allGateways += New-SCDefaultGateway -IPAddress "172.22.22.254" -Automatic

    # DNS servers
    $allDnsServer = @("172.22.22.1", "172.22.23.1")

    # DNS suffixes
    $allDnsSuffixes = @()

    New-SCStaticIPAddressPool -Name "Management-LN_0_pool_0" -LogicalNetworkDefinition $logicalNetworkDefinition -Subnet "172.22.22.0/24" -IPAddressRangeStart "172.22.22.1" -IPAddressRangeEnd "172.22.22.254" -DefaultGateway $allGateways -DNSServer $allDnsServer -DNSSuffix "cloudmigration.hu" -DNSSearchSuffix $allDnsSuffixes -NetworkRoute $allNetworkRoutes -RunAsynchronously
 #>

# 2. Create VM networks: Create VM networks that map to network sites that exist within your physical networks.
<# 
    $logicalNetwork = Get-SCLogicalNetwork -ID "cf9d1c77-e5e9-4b93-a885-9cdc4e050df5"
    $vmNetwork = New-SCVMNetwork -Name "Management-VMNET" -LogicalNetwork $logicalNetwork -IsolationType "NoIsolation"
    Write-Output $vmNetwork
#>

# 3. Set up IP address pools: Create address pool to allocate static IP addresses. You'll need to configure pools for logical networks, and in some circumstances for VM networks too.
# 4. Add a gateway: You might need to set up network virtualization gateways in the VMM networking fabric. By default, if you're using isolated VM networks in your VMM fabric, VMs associated with a network can only connect to machines in the same subnet. If you want to connect VMs further than the subnet, you'll need a gateway.

# 5. Create port profiles: Create uplink port profiles that indicate to VMM which networks a host can connect to on a specific network adapter. If necessary, create virtual port profiles to specify settings that must be applied to virtual network adapters. You can create custom port classifications to abstract virtual port profiles.
<# 
    $definition = @()
    $definition += Get-SCLogicalNetworkDefinition -ID "da803c1b-c11f-4534-902a-22a32f3feafa"
    New-SCNativeUplinkPortProfile -Name "Management_PP" -Description "Create port profiles: Create uplink port profiles that indicate to VMM which networks a host can connect to on a specific network adapter. If necessary, create virtual port profiles to specify settings that must be applied to virtual network adapters. You can create custom port classifications to abstract virtual port profiles." -LogicalNetworkDefinition $definition -EnableNetworkVirtualization $false -LBFOLoadBalancingAlgorithm "HostDefault" -LBFOTeamMode "SwitchIndependent" -RunAsynchronously
#>

# 6. Configure logical switches: Create a logical switch, apply it to a host, and select the network adapters on the host that you want to bind to the switch. When you apply the switch, networking settings will be applied to the host.

# ***** OMG - THIS IS HARDCORE, WAS ALWAYS HARDCORE. I NEED TO DO THIS IN VMM GUI :) VMware NSX-T is much easier to configure. Kubernetes networking with Calico pluggable networking is also easier, haha! 
<# 
    New-SCVirtualNetworkAdapterNativePortProfile -Name "Management_PP" -Description "This is important Hyper-V Port Profile." -AllowIeeePriorityTagging $false -AllowMacAddressSpoofing $false -AllowTeaming $false -EnableDhcpGuard $false -EnableGuestIPNetworkVirtualizationUpdates $true -EnableIov $false -EnableVrss $false -EnableIPsecOffload $false -EnableRouterGuard $false -EnableVmq $false -EnableRdma $false -MinimumBandwidthWeight "0" -RunAsynchronously
    New-SCPortClassification -Name "VM_Traffic_PPC"

    $logicalSwitch = New-SCLogicalSwitch -Name "Management_LS" -Description "Configure logical switches: Create a logical switch, apply it to a host, and select the network adapters on the host that you want to bind to the switch. When you apply the switch, networking settings will be applied to the host." -EnableSriov $false -SwitchUplinkMode "NoTeam" -MinimumBandwidthMode "Weight"

    # Get Network Port Classification 'VM_Traffic_PPC'
    $portClassification = Get-SCPortClassification -ID "6dc58b57-c97f-4925-b4b2-92c3bda4d5cb"
    # Get Hyper-V Switch Port Profile 'Management_PP'
    $nativeProfile = Get-SCVirtualNetworkAdapterNativePortProfile -ID "9b0143ee-2b19-4d6f-b272-8839e534b579"
    New-SCVirtualNetworkAdapterPortProfileSet -Name "VM_Traffic_PPC" -PortClassification $portClassification -LogicalSwitch $logicalSwitch -RunAsynchronously -VirtualNetworkAdapterNativePortProfile $nativeProfile
    # Get Native Uplink Port Profile 'Management_PP'
    $nativeUppVar = Get-SCNativeUplinkPortProfile -ID "967c9f8c-8ff6-45e1-a4d7-47c52a103661"
    $uppSetVar = New-SCUplinkPortProfileSet -Name "Management_PP" -LogicalSwitch $logicalSwitch -NativeUplinkPortProfile $nativeUppVar -RunAsynchronously
    # Get VM Network 'Management-VMNET'
    $vmNetwork = Get-SCVMNetwork -ID "c898f1b1-2f95-45e4-9326-b377e7cb476c"
    # Get Network Port Classification 'VM_Traffic_PPC'
    $vNICPortClassification = Get-SCPortClassification -ID "6dc58b57-c97f-4925-b4b2-92c3bda4d5cb"
    New-SCLogicalSwitchVirtualNetworkAdapter -Name "Management-VMNET-NA" -UplinkPortProfileSet $uppSetVar -RunAsynchronously -VMNetwork $vmNetwork -VLanEnabled $true -VLanID 1 -PortClassification $vNICPortClassification -IsUsedForHostManagement $true -InheritsAddressFromPhysicalNetworkAdapter $false -IPv4AddressType "Dynamic" -IPv6AddressType "Dynamic"
#>

# Parameters
$LogicalNetworkName = "Management-LN"
$NetworkSiteName = "Management-NS"
$LogicalSwitchName = "Management-LS"
$UplinkPortProfileName = "Management-UPP"
$VMNetworkName = "Management-VMNET"
$HostGroupName = "All Hosts"  # Adjust if needed
$MyHost = Get-SCVMHost -ComputerName "HV01" # Ensured as per user preference
$VirtualSwitchName = "vSwitch-External-MGMNT"
$Subnet = "172.22.22.0/24"

function Debug-Log($Message) {
    Write-Host "[DEBUG] $Message" -ForegroundColor Yellow
}

# Step 1: Retrieve the Host Group
Debug-Log "Retrieving Host Group: '$HostGroupName'..."
$HostGroup = Get-SCVMHostGroup -Name $HostGroupName -ErrorAction SilentlyContinue

if (-not $HostGroup) {
    Debug-Log "Error: Host Group '$HostGroupName' not found!"
    $HostGroupName = Read-Host "Please enter the correct Host Group name"
    $HostGroup = Get-SCVMHostGroup -Name $HostGroupName -ErrorAction SilentlyContinue
    if (-not $HostGroup) {
        Write-Error "Host Group '$HostGroupName' still not found. Exiting."
        Exit
    }
}

Debug-Log "Using Host Group: '$($HostGroup.Name)'"

# Step 2: Create Logical Network
Debug-Log "Checking for existing Logical Network '$LogicalNetworkName'..."
$LogicalNetwork = Get-SCLogicalNetwork -Name $LogicalNetworkName -ErrorAction SilentlyContinue
if ($LogicalNetwork) {
    Debug-Log "Logical Network '$LogicalNetworkName' already exists. Skipping creation."
} else {
    $Confirm = Read-Host "Logical Network '$LogicalNetworkName' does not exist. Create it? (Y/N)"
    if ($Confirm -eq "Y") {
        Debug-Log "Executing: New-SCLogicalNetwork -Name $LogicalNetworkName"
        $LogicalNetwork = New-SCLogicalNetwork -Name $LogicalNetworkName `
            -VMMServer "VMM01A" `
            -Description "Logical Network for Management Traffic"
        Debug-Log "Logical Network '$LogicalNetworkName' created successfully."
    } else {
        Debug-Log "Skipping Logical Network creation."
        Exit
    }
}

# Step 3: Create Network Site
Debug-Log "Checking for existing Network Site '$NetworkSiteName'..."
$NetworkSite = Get-SCLogicalNetworkDefinition -LogicalNetwork $LogicalNetwork -ErrorAction SilentlyContinue | Where-Object { $_.Name -eq $NetworkSiteName }
if ($NetworkSite) {
    Debug-Log "Network Site '$NetworkSiteName' already exists. Skipping creation."
} else {
    $Confirm = Read-Host "Network Site '$NetworkSiteName' does not exist. Create it? (Y/N)"
    if ($Confirm -eq "Y") {
        Debug-Log "Executing: New-SCLogicalNetworkDefinition -Name $NetworkSiteName"
        $NetworkSite = New-SCLogicalNetworkDefinition `
            -LogicalNetwork $LogicalNetwork `
            -Name $NetworkSiteName `
            -VMHostGroup $HostGroup `
            -SubnetVLan $Subnet
        Debug-Log "Network Site '$NetworkSiteName' created successfully."
    } else {
        Debug-Log "Skipping Network Site creation."
        Exit
    }
}

# Step 4: Create Logical Switch
Debug-Log "Checking for existing Logical Switch '$LogicalSwitchName'..."
$LogicalSwitch = Get-SCLogicalSwitch -Name $LogicalSwitchName -ErrorAction SilentlyContinue
if ($LogicalSwitch) {
    Debug-Log "Logical Switch '$LogicalSwitchName' already exists. Skipping creation."
} else {
    $Confirm = Read-Host "Logical Switch '$LogicalSwitchName' does not exist. Create it? (Y/N)"
    if ($Confirm -eq "Y") {
        Debug-Log "Executing: New-SCLogicalSwitch -Name $LogicalSwitchName"
        $LogicalSwitch = New-SCLogicalSwitch -Name $LogicalSwitchName -Description "Logical Switch for Management Traffic"
        Debug-Log "Logical Switch '$LogicalSwitchName' created successfully."
    } else {
        Debug-Log "Skipping Logical Switch creation."
        Exit
    }
}

# Step 5: Create Uplink Port Profile
Debug-Log "Checking for existing Uplink Port Profile '$UplinkPortProfileName'..."
$UplinkPortProfile = Get-SCUplinkPortProfileSet -Name $UplinkPortProfileName -ErrorAction SilentlyContinue
if ($UplinkPortProfile) {
    Debug-Log "Uplink Port Profile '$UplinkPortProfileName' already exists. Skipping creation."
} else {
    $Confirm = Read-Host "Uplink Port Profile '$UplinkPortProfileName' does not exist. Create it? (Y/N)"
    if ($Confirm -eq "Y") {
        Debug-Log "Executing: New-SCUplinkPortProfileSet -Name $UplinkPortProfileName"
        $UplinkPortProfile = New-SCUplinkPortProfileSet -Name $UplinkPortProfileName `
            -LogicalSwitch $LogicalSwitch
        Debug-Log "Uplink Port Profile '$UplinkPortProfileName' created successfully."
    } else {
        Debug-Log "Skipping Uplink Port Profile creation."
        Exit
    }
}

# Step 6: Associate Logical Switch with Hyper-V Virtual Switch
Debug-Log "Retrieving VM Host Network Adapters..."
$HostNetworkAdapters = Get-SCVMHostNetworkAdapter -VMHost $MyHost

Debug-Log "Found Network Adapters:"
$HostNetworkAdapters | Format-Table Name, VirtualNetwork, IPAddresses -AutoSize

$HostNetworkAdapter = $HostNetworkAdapters | Where-Object { $_.VirtualNetwork -eq $VirtualSwitchName }

if ($HostNetworkAdapter) {
    Debug-Log "Using Adapter: $($HostNetworkAdapter.Name) with Virtual Switch: $($HostNetworkAdapter.VirtualNetwork)"
    
    Debug-Log "Executing: Add-SCVMHostNetworkAdapter"
    Add-SCVMHostNetworkAdapter `
        -VMHostNetworkAdapter $HostNetworkAdapter `
        -LogicalSwitch $LogicalSwitch `
        -UplinkPortProfile $UplinkPortProfile `
        -EnableTeaming $false
    Debug-Log "Logical Switch '$LogicalSwitchName' successfully associated with Virtual Switch '$VirtualSwitchName'."
} else {
    Debug-Log "Error: Hyper-V Virtual Switch '$VirtualSwitchName' not found on host '$MyHost'. Ensure the switch exists before proceeding."
    Exit
}

# Step 7: Create VM Network
Debug-Log "Checking for existing VM Network '$VMNetworkName'..."
$VMNetwork = Get-SCVMNetwork -Name $VMNetworkName -ErrorAction SilentlyContinue
if ($VMNetwork) {
    Debug-Log "VM Network '$VMNetworkName' already exists. Skipping creation."
} else {
    $Confirm = Read-Host "VM Network '$VMNetworkName' does not exist. Create it? (Y/N)"
    if ($Confirm -eq "Y") {
        Debug-Log "Executing: New-SCVMNetwork -Name $VMNetworkName"
        $VMNetwork = New-SCVMNetwork `
            -Name $VMNetworkName `
            -LogicalNetwork $LogicalNetwork `
            -IsolationType "None" `
            -Description "VM Network for Management Traffic"
        Debug-Log "VM Network '$VMNetworkName' created successfully."
    } else {
        Debug-Log "Skipping VM Network creation."
        Exit
    }
}

# Final Verification
Debug-Log "Configuration steps completed. Verify the following in the VMM GUI:"
Debug-Log "1. Logical Network: '$LogicalNetworkName'"
Debug-Log "2. Network Site: '$NetworkSiteName'"
Debug-Log "3. Logical Switch: '$LogicalSwitchName' with Uplink Port Profile '$UplinkPortProfileName'"
Debug-Log "4. VM Network: '$VMNetworkName' associated with Logical Network '$LogicalNetworkName'"
Debug-Log "Check your configuration in the VMM Fabric and Networking views."
