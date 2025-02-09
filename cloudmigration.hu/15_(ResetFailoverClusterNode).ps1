# Define the node to reset (run this script on the local node)
$NodeName = $env:COMPUTERNAME

Write-Host "Stopping the Cluster Service on $NodeName..." -ForegroundColor Cyan
# Stop the Cluster Service
Stop-Service -Name ClusSvc -Force -ErrorAction SilentlyContinue

Write-Host "Removing Failover Clustering feature from $NodeName..." -ForegroundColor Cyan
# Uninstall Failover Clustering
Uninstall-WindowsFeature -Name Failover-Clustering -ErrorAction SilentlyContinue

Write-Host "Clearing cluster configuration files on $NodeName..." -ForegroundColor Cyan
# Remove cluster configuration files
Remove-Item -Path "C:\Windows\Cluster" -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "Removing registry entries related to Failover Clustering..." -ForegroundColor Cyan
# Remove Failover Clustering registry entries
$ClusterRegistryPath = "HKLM:\SYSTEM\CurrentControlSet\Services\ClusSvc"
if (Test-Path $ClusterRegistryPath) {
    Remove-Item -Path $ClusterRegistryPath -Recurse -Force -ErrorAction SilentlyContinue
}

# Prompt user before restarting the server
Write-Host "Cluster configuration has been reset on $NodeName." -ForegroundColor Green
Write-Host "A restart is required to finalize the changes." -ForegroundColor Yellow
$UserResponse = Read-Host "Do you want to restart the server now? (Y/N)"

if ($UserResponse -eq "Y" -or $UserResponse -eq "y") {
    Write-Host "Restarting $NodeName..." -ForegroundColor Cyan
    Restart-Computer -Force
} else {
    Write-Host "Restart skipped. Please remember to restart $NodeName manually to complete the reset process." -ForegroundColor Yellow
}
