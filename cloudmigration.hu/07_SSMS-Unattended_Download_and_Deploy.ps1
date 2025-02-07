# Define Variables
$SSMSInstallerUrl = "https://aka.ms/ssmsfullsetup"
$InstallerPath = "$env:TEMP\SSMS-Setup.exe"

Write-Host "[INFO] Downloading SQL Server Management Studio..."

# Use BitsTransfer for more reliable download
Start-BitsTransfer -Source $SSMSInstallerUrl -Destination $InstallerPath

if (-Not (Test-Path $InstallerPath)) {
    Write-Host "[ERROR] Failed to download SSMS installer. Check your internet connection."; exit 1
}

Write-Host "[INFO] Installing SQL Server Management Studio..."

# Install SSMS Silently
Start-Process -FilePath $InstallerPath -ArgumentList "/install", "/quiet", "/norestart" -Wait -NoNewWindow

if ($?) {
    Write-Host "[INFO] SQL Server Management Studio installation completed successfully."
} else {
    Write-Host "[ERROR] SQL Server Management Studio installation encountered an issue. Check logs."
}

# Cleanup
Remove-Item -Path $InstallerPath -Force
Write-Host "[INFO] Installation complete. Temporary files removed."
