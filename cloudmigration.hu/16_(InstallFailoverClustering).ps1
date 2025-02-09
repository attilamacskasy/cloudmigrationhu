# WARNING: This script is experimental. I used Windows GUI to create Failover Cluster, because of required validation and configuration is too complex to automate at this point (based on my knowledge).
# I will try to automate this process using PowerShell. 

# I will use the Install-WindowsFeature cmdlet to install the Failover Clustering feature and the Set-Service cmdlet to configure the Cluster Service to start automatically. 
# I will also verify that the Cluster Service is running after the installation.
# I will run this script on each node in the cluster to ensure that Failover Clustering is installed and configured correctly.

# Define the node (local machine)
$NodeName = $env:COMPUTERNAME

Write-Host "Starting Failover Clustering installation on $NodeName..." -ForegroundColor Cyan

# Install Failover Clustering feature
Write-Host "Installing Failover Clustering feature..." -ForegroundColor Yellow
Install-WindowsFeature -Name Failover-Clustering -IncludeManagementTools -ErrorAction Stop

# Check if the feature was installed successfully
$FeatureStatus = Get-WindowsFeature -Name Failover-Clustering
if ($FeatureStatus.Installed) {
    Write-Host "Failover Clustering feature installed successfully on $NodeName." -ForegroundColor Green
} else {
    Write-Host "Failed to install Failover Clustering feature. Please check the logs and try again." -ForegroundColor Red
    exit 1
}

# Enable the Cluster Service and set it to start automatically
Write-Host "Configuring the Cluster Service..." -ForegroundColor Yellow
Set-Service -Name ClusSvc -StartupType Automatic
Start-Service -Name ClusSvc

# Verify the Cluster Service is running
$ClusterServiceStatus = Get-Service -Name ClusSvc
if ($ClusterServiceStatus.Status -eq "Running") {
    Write-Host "Cluster Service is running on $NodeName." -ForegroundColor Green
} else {
    Write-Host "Cluster Service failed to start. Please troubleshoot the issue." -ForegroundColor Red
    exit 1
}

Write-Host "Failover Clustering installation and configuration completed successfully!" -ForegroundColor Green
