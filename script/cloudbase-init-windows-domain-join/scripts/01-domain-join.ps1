<#
.SYNOPSIS
    Domain join script executed by Cloudbase-Init LocalScripts plugin.

.DESIGN
    - Runs once at first boot
    - Joins the VM to an AD domain
    - Can be extended later to read parameters from user-data / JSON
#>

$LogPath = "C:\CloudInit\DomainJoin.log"
New-Item -ItemType Directory -Path (Split-Path $LogPath) -Force | Out-Null

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp `t $Message" | Tee-Object -FilePath $LogPath -Append
}

try {
    Write-Log "=== Domain join script starting ==="

    # --- CONFIG: LAB DEFAULTS (can be parameterized later) ---
    $DomainName        = "lab.example.com"
    $DomainJoinUser    = "LAB\\joinuser"
    $DomainJoinPassRaw = "SuperSecretPassword123!"
    $TargetOU          = "OU=Workstations,OU=Lab,DC=lab,DC=example,DC=com"

    # --- WAIT FOR NETWORK ---
    Write-Log "Waiting for network connectivity..."
    $maxTries = 30
    for ($i = 1; $i -le $maxTries; $i++) {
        if (Test-Connection -ComputerName $DomainName -Count 1 -Quiet) {
            Write-Log "Network / DNS looks ready."
            break
        }
        Write-Log "DNS not ready yet (attempt $i/$maxTries), sleeping 5s..."
        Start-Sleep -Seconds 5
    }

    # --- ALREADY JOINED? ---
    $currentDomain = (Get-WmiObject Win32_ComputerSystem).Domain
    if ($currentDomain -eq $DomainName) {
        Write-Log "Machine is already joined to $DomainName, nothing to do."
        exit 0
    }

    # --- CREDENTIALS ---
    $securePass = ConvertTo-SecureString $DomainJoinPassRaw -AsPlainText -Force
    $creds      = New-Object System.Management.Automation.PSCredential($DomainJoinUser, $securePass)

    # --- DOMAIN JOIN ---
    Write-Log "Calling Add-Computer to join $DomainName..."
    Add-Computer -DomainName $DomainName -Credential $creds -OUPath $TargetOU -ErrorAction Stop -Force

    Write-Log "Domain join successful. Scheduling reboot."
    # We don't reboot here; Cloudbase-Init can be configured to allow
    # reboot or we can just trigger it directly:
    shutdown.exe /r /t 30 /c "Domain join complete, rebooting"

    Write-Log "=== Domain join script completed successfully ==="
    exit 0
}
catch {
    Write-Log "ERROR: $($_.Exception.Message)"
    Write-Log "StackTrace: $($_.Exception.StackTrace)"
    # Non-zero exit so Cloudbase-Init may re-run the script on next boot.
    exit 1
}
