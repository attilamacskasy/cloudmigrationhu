# Attila's amazing script to reconfigure Nested Hyper-V VMs in a cluster - adjust the memory and processor configurations based on demand.
# because these nested Hyper-V servers has a habit of eating up all the resources :)

# Available VM Configuration Options:

# Option     Memory Processors CoresPerProcessor
# ------     ------ ---------- -----------------
# 1 - Small  8 GB            1                 1
# 2 - Medium 16 GB           2                 2
# 3 - Large  32 GB           4                 4

# This script allows you to reconfigure multiple VMware virtual machines (VMs) in a cluster by updating their .vmx files with new memory and processor configurations.
# The script prompts the user to select a configuration option (small, medium, or large) and then applies the chosen configuration to each VM in the specified paths.

# what the scipt change in vmx configuration file?

# memsize = "8192"
# numvcpus = "1"
# cpuid.coresPerSocket = "1"

# !!! IMPORTANT NOTE !!! (before you complain)
# Changes made to the .vmx file do not take effect until the next time VMware Workstation or VMware Player is opened. 
# If the application is currently open, quit it and re-open for the changes to take effect. 
# PRO TIP: Alternatively, close the VM in Workstation and double-click the .vmx file to apply the changes and open the virtual machine immediately. See: Reconfigure_HV_Cluster.jpg
# Read more: https://knowledge.broadcom.com/external/article/311480/editing-the-vmx-file-of-a-vmware-worksta.html

# Define the VM paths
$vms = @(
    @{ Name = "HV01"; Path = "C:\HV01\HV01.vmx" },
    @{ Name = "HV02"; Path = "D:\HV02\HV02.vmx" },
    @{ Name = "HV03"; Path = "E:\HV03\HV03.vmx" }
)

# Function to display host system information, example output below:
<#
Host System Information:
---------------------------------
CPU: AMD Ryzen 9 3900XT 12-Core Processor
CPU Cores: 12
Total Memory: 131,020 MB
Used Memory: 41,738 MB
Available Memory: 89,282 MB
---------------------------------
#>
function Get-HostInfo {
    Write-Host "Gathering host system information..." -ForegroundColor Cyan
    
    # Get total memory
    $totalMemory = (Get-CimInstance -ClassName Win32_ComputerSystem).TotalPhysicalMemory / 1MB

    # Get available memory using Get-Counter
    $availableMemory = (Get-Counter -Counter "\Memory\Available MBytes").CounterSamples[0].CookedValue

    # Calculate used memory
    $usedMemory = $totalMemory - $availableMemory

    # Get CPU info
    $cpuInfo = Get-CimInstance -ClassName Win32_Processor
    $cpuName = $cpuInfo.Name
    $cpuCores = $cpuInfo.NumberOfCores

    # Display host information
    Write-Host ""
    Write-Host "Host System Information:" -ForegroundColor Cyan
    Write-Host "---------------------------------"
    Write-Host ("CPU: {0}" -f $cpuName)
    Write-Host ("CPU Cores: {0}" -f $cpuCores)
    Write-Host ("Total Memory: {0:N0} MB" -f $totalMemory)
    Write-Host ("Used Memory: {0:N0} MB" -f $usedMemory)
    Write-Host ("Available Memory: {0:N0} MB" -f $availableMemory)
    Write-Host "---------------------------------"
    Write-Host ""
}

# Display host system information
Get-HostInfo

# Display notice about powered-off state
Write-Host "IMPORTANT: Ensure all VMs are powered off before running this script." -ForegroundColor Yellow
Write-Host "Press Enter to continue or Ctrl+C to cancel." -ForegroundColor Yellow
Read-Host

# Display options in a table format
Write-Host "Available VM Configuration Options:" -ForegroundColor Cyan
Write-Host ""
$configurationOptions = @(
    [PSCustomObject]@{ Option = "1 - Small"; Memory = "8 GB"; Processors = 1; CoresPerProcessor = 1 },
    [PSCustomObject]@{ Option = "2 - Medium"; Memory = "16 GB"; Processors = 2; CoresPerProcessor = 2 },
    [PSCustomObject]@{ Option = "3 - Large"; Memory = "32 GB"; Processors = 4; CoresPerProcessor = 4 }
)
$configurationOptions | Format-Table -AutoSize

# Prompt user for a choice
Write-Host ""
$configChoice = Read-Host "Enter the number for the configuration option (1-Small, 2-Medium, 3-Large)"

# Map the choice to configuration values
switch ($configChoice) {
    "1" {
        $memorySizeMB = 8192
        $numProcessors = 1
        $numCoresPerProcessor = 1
    }
    "2" {
        $memorySizeMB = 16384
        $numProcessors = 2
        $numCoresPerProcessor = 2
    }
    "3" {
        $memorySizeMB = 32768
        $numProcessors = 4
        $numCoresPerProcessor = 4
    }
    default {
        Write-Host "Invalid option selected. Exiting script."
        exit
    }
}

# Apply the configuration to each VM
foreach ($vm in $vms) {
    $vmPath = $vm.Path
    $vmName = $vm.Name
    
    if (Test-Path $vmPath) {
        Write-Host "Processing VM: $vmName"

        # Create a backup of the .vmx file
        $backupPath = "$vmPath.bak"
        Copy-Item -Path $vmPath -Destination $backupPath -Force
        Write-Host "Backup created for ${vmName}: $backupPath"

        # Read the VMX file
        $vmxContent = Get-Content -Path $vmPath

        # Update or add memory configuration
        if ($vmxContent -match "^memsize\s*=") {
            $vmxContent = $vmxContent -replace "^memsize\s*=.*", "memsize = `"$memorySizeMB`""
        } else {
            $vmxContent += "memsize = `"$memorySizeMB`""
        }

        # Update or add processor configuration
        if ($vmxContent -match "^numvcpus\s*=") {
            $vmxContent = $vmxContent -replace "^numvcpus\s*=.*", "numvcpus = `"$numProcessors`""
        } else {
            $vmxContent += "numvcpus = `"$numProcessors`""
        }

        # Update or add cores per processor configuration
        if ($vmxContent -match "^cpuid.coresPerSocket\s*=") {
            $vmxContent = $vmxContent -replace "^cpuid.coresPerSocket\s*=.*", "cpuid.coresPerSocket = `"$numCoresPerProcessor`""
        } else {
            $vmxContent += "cpuid.coresPerSocket = `"$numCoresPerProcessor`""
        }

        # Write updated configuration back to the VMX file
        Set-Content -Path $vmPath -Value $vmxContent

        Write-Host "Configuration updated for VM: $vmName"
    } else {
        Write-Host "VMX file not found for VM: $vmName"
    }
}
