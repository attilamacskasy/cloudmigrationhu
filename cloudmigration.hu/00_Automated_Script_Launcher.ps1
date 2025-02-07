# Define repository path (now located on Desktop)
$repoPath = "$env:USERPROFILE\Desktop\cloudmigrationhu\cloudmigration.hu"
$stateFile = "$env:USERPROFILE\Desktop\server_config_state.txt"
$logFile = "$env:USERPROFILE\Desktop\server_config_log.txt"

# Ensure the repository path is accessible
if (!(Test-Path $repoPath)) {
    Write-Host "ERROR: Repository path not found on Desktop! Ensure 'cloudmigrationhu' exists." -ForegroundColor Red
    Exit
}

# Create state file if it doesn't exist
if (!(Test-Path $stateFile)) {
    Set-Content -Path $stateFile -Value "" -Force
}

# Read existing state
$completedScripts = Get-Content -Path $stateFile -ErrorAction SilentlyContinue

# Retrieve scripts ensuring only one from "01_*_2025.ps1"
$scriptList = @()
$script01 = Get-ChildItem -Path $repoPath -Filter "01_*_2025.ps1" | Sort-Object Name
$script02 = Get-ChildItem -Path $repoPath -Filter "02_*.ps1" | Sort-Object Name
$script05 = Get-ChildItem -Path $repoPath -Filter "05_*.ps1" | Sort-Object Name

# Add scripts to the ordered list
if ($script01) { $scriptList += $script01 }
if ($script02) { $scriptList += $script02 }
if ($script05) { $scriptList += $script05 }

# Convert to an array with status tracking
$scripts = $scriptList | ForEach-Object {
    [PSCustomObject]@{
        Name = $_.Name
        Path = $_.FullName
        Status = if ($completedScripts -contains $_.Name) { "x" } else { " " }
    }
}

# If no scripts are found, display a message and exit
if ($scripts.Count -eq 0) {
    Write-Host "No scripts found in the repository." -ForegroundColor Red
    Exit
}

# Function to display the menu
function Show-Menu {
    Clear-Host
    Write-Host "Welcome to Server Config`n"
    $index = 1
    foreach ($script in $scripts) {
        Write-Host "[$($script.Status)] $index. $($script.Name)"
        $index++
    }
    Write-Host "`nPress Enter to run the next script or type 'exit' to quit:"
}

# Execution loop
while ($true) {
    Show-Menu

    # Automatically select the next incomplete script
    $nextScriptIndex = $scripts | Where-Object { $_.Status -eq " " }

    # If no scripts are left, display a message and exit
    if (-not $nextScriptIndex) {
        Write-Host "All scripts have been executed!" -ForegroundColor Green
        break
    }

    $selectedScript = $nextScriptIndex[0]

    # Wait for Enter or exit command
    $input = Read-Host
    if ($input -eq "exit") { break }

    # Run the selected script
    try {
        Write-Host "Running $($selectedScript.Name)..." -ForegroundColor Green
        & PowerShell -ExecutionPolicy Bypass -File $selectedScript.Path | Tee-Object -FilePath $logFile -Append
        Write-Host "Script completed successfully!" -ForegroundColor Green
        
        # Mark as completed and update status
        $selectedScript.Status = "x"
        Add-Content -Path $stateFile -Value $selectedScript.Name
        
        # Refresh the state for the menu
        $completedScripts = Get-Content -Path $stateFile -ErrorAction SilentlyContinue
        $scripts = $scriptList | ForEach-Object {
            [PSCustomObject]@{
                Name = $_.Name
                Path = $_.FullName
                Status = if ($completedScripts -contains $_.Name) { "x" } else { " " }
            }
        }
    } catch {
        Write-Host "Error running script: $_" -ForegroundColor Red
    }

    Start-Sleep 2
}