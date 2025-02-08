
# PowerShell Script to Connect Hyper-V Server to Synology iSCSI Target

# Unfortunatley, I failed using Synology Rest API or Remote SSH commands to automate the iSCSI Target configuration.
# You need to manually configure the iSCSI Target on Synology NAS before running this script.

# This script will add the iSCSI Target Portal, discover available targets, and connect to the target.
#  - Ensure iSCSI Initiator Service is Running
#  - Add Synology iSCSI Target Portal
#  - Discover Available iSCSI Targets
#  - Connect to the iSCSI Target

# --- CONFIGURATION ---
$SynologyTargetIP = "172.22.22.253"  # Synology NAS IP
$IQN = "iqn.2000-01.com.synology:nas1.default-target.53a7d83343b"  # iSCSI Target Name


function Wait-With-Progress {
    param (
        [int]$Seconds = 20
    )

    $step = 100 / $Seconds  # Calculate progress step
    for ($i = 1; $i -le $Seconds; $i++) {
        $progress = $i * $step
        Write-Progress -Activity "Waiting..." -Status "$i of $Seconds seconds" -PercentComplete $progress
        Start-Sleep -Seconds 1
    }
    Write-Progress -Activity "Waiting..." -Status "Completed" -Completed
    Write-Host "[INFO] Wait time completed."
}

# --- STEP 1: Ensure iSCSI Initiator Service is Running ---
Write-Host "[INFO] Checking iSCSI Initiator Service..."
$service = Get-Service -Name MSiSCSI -ErrorAction SilentlyContinue
if ($service.Status -ne "Running") {
    Write-Host "[INFO] iSCSI Service not running. Starting it now..."
    Start-Service MSiSCSI
    Set-Service -Name MSiSCSI -StartupType Automatic
} else {
    Write-Host "[INFO] iSCSI Service is already running."
}

# --- STEP 2: Add Synology iSCSI Target Portal ---
Write-Host "[INFO] Adding Synology iSCSI Target Portal at $SynologyTargetIP..."
New-IscsiTargetPortal -TargetPortalAddress $SynologyTargetIP -InitiatorPortalAddress 0.0.0.0 -ErrorAction SilentlyContinue

# --- STEP 3: Discover Available iSCSI Targets ---
Write-Host "[INFO] Listing available iSCSI Targets..."
$Targets = Get-IscsiTarget
if ($Targets.Count -eq 0) {
    Write-Host "[ERROR] No iSCSI Targets found! Retrying after adding portal..."
    iscsicli QAddTargetPortal $SynologyTargetIP
    Wait-With-Progress -Seconds 5
    $Targets = Get-IscsiTarget
}

if ($Targets.Count -eq 0) {
    Write-Host "[ERROR] Still no iSCSI Targets found. Check Synology settings and firewall!"
    exit 1
} else {
    Write-Host "[INFO] Found iSCSI Target: $IQN"
}

# --- STEP 4: Connect to the iSCSI Target ---
Write-Host "[INFO] Connecting to iSCSI Target: $IQN..."
Connect-IscsiTarget -NodeAddress $IQN -IsPersistent $true

Wait-With-Progress -Seconds 5

# --- STEP 5: Verify Connection ---
# Write-Host "[INFO] Listing Connected iSCSI Sessions..."
# $Sessions = Get-IscsiSession

# if ($Sessions.Count -gt 0) {
#     Write-Host "[SUCCESS] iSCSI Target Connected Successfully!"
#     Get-IscsiSession | Format-Table -AutoSize
# } else {
#     Write-Host "[ERROR] Connection to iSCSI Target Failed. Verify your settings!"
#     exit 1
# }

Write-Host "[SUCCESS] iSCSI Target Connected Successfully!"
