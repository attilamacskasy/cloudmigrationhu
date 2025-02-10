# Set Debug Mode (Change to $true for more details)
$DebugMode = $true

# Log file location
$LogFile = "$env:TEMP\WAC_Connectivity_Check.log"

# Define Local Services (Servers in cloudmigration.hu)
$LocalServers = @(
    # "DC01.cloudmigration.hu",
    # "DB01A.cloudmigration.hu",
    # "HV01.cloudmigration.hu",
    # "HVCL01.cloudmigration.hu"
    "DC01",
    "DB01A",
    "HV01"
)

# Function to log messages
function Log-Message {
    param (
        [string]$Message,
        [string]$Type = "INFO"
    )
    $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogEntry = "[$TimeStamp] [$Type] $Message"
    
    # Output to console
    if ($Type -eq "ERROR") {
        Write-Host $LogEntry -ForegroundColor Red
    } elseif ($Type -eq "DEBUG" -and $DebugMode) {
        Write-Host $LogEntry -ForegroundColor Yellow
    } else {
        Write-Host $LogEntry -ForegroundColor Green
    }

    # Append to log file
    Add-Content -Path $LogFile -Value $LogEntry
}

# Start Testing
Log-Message "Starting WAC Internet & Local Service Connection Checker Tool..." "INFO"

# Test 1: Ping Google DNS (8.8.8.8)
Log-Message "Testing Ping to 8.8.8.8..." "DEBUG"
$PingTest = Test-Connection -ComputerName 8.8.8.8 -Count 2 -Quiet
if ($PingTest) {
    Log-Message "Ping Test: Success (Internet might be working)" "INFO"
} else {
    Log-Message "Ping Test: Failed (No response from 8.8.8.8)" "ERROR"
}

# Test 2: HTTP Connection Test to Google
Log-Message "Testing HTTP connectivity to Google..." "DEBUG"
$WebTest = (Test-NetConnection -ComputerName google.com -Port 80).TcpTestSucceeded
if ($WebTest) {
    Log-Message "Web Test: Success (Can reach Google.com)" "INFO"
} else {
    Log-Message "Web Test: Failed (Google.com not reachable)" "ERROR"
}

# Test 3: DNS Resolution Test
Log-Message "Testing DNS Resolution for Google.com..." "DEBUG"
try {
    $DNSTest = Resolve-DnsName google.com -ErrorAction Stop
    if ($DNSTest.Count -gt 0) {
        Log-Message "DNS Test: Success (DNS is resolving correctly)" "INFO"
    }
} catch {
    Log-Message "DNS Test: Failed (DNS resolution not working)" "ERROR"
}

# Final Internet Summary
if ($PingTest -and $WebTest -and $DNSTest) {
    Log-Message "Internet Connection Status: ONLINE" "INFO"
} else {
    Log-Message "Internet Connection Status: OFFLINE" "ERROR"
}

# Test 4: Check Local Services (Domain, Database, and Hypervisors)
Log-Message "Checking Local Network Access to CloudMigration.hu Services..." "INFO"

foreach ($server in $LocalServers) {
    Log-Message "Testing connection to $server..." "DEBUG"

    # Test connection via Ping
    $LocalPingTest = Test-Connection -ComputerName $server -Count 2 -Quiet
    if ($LocalPingTest) {
        Log-Message "{$server}: Reachable via Ping" "INFO"
    } else {
        Log-Message "{$server}: Unreachable via Ping" "ERROR"
        continue # Skip further tests for this server
    }

    # Test connection via RDP (Port 3389)
    Log-Message "Testing RDP (Port 3389) on $server..." "DEBUG"
    $RDPTest = (Test-NetConnection -ComputerName $server -Port 3389).TcpTestSucceeded
    if ($RDPTest) {
        Log-Message "{$server}: RDP is accessible" "INFO"
    } else {
        Log-Message "{$server}: RDP is not responding" "ERROR"
    }

    # Test connection via SMB (Port 445)
    Log-Message "Testing SMB (Port 445) on $server..." "DEBUG"
    $SMBTest = (Test-NetConnection -ComputerName $server -Port 445).TcpTestSucceeded
    if ($SMBTest) {
        Log-Message "{$server}: SMB is accessible" "INFO"
    } else {
        Log-Message "{$server}: SMB is not responding" "ERROR"
    }
}

# End of Checks
Log-Message "WAC Internet & Local Service Connection Checker Tool completed!" "INFO"

# Open Log File
Start-Sleep -Seconds 1
Invoke-Item -Path $LogFile
