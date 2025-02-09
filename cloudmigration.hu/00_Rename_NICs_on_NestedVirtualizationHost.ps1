# Get network adapters
$adapter1 = Get-NetAdapter | Where-Object { $_.Name -eq "Ethernet" }
$adapter2 = Get-NetAdapter | Where-Object { $_.Name -eq "Ethernet 2" }

# Rename "Ethernet" to "ETH1G"
if ($adapter1) {
    Rename-NetAdapter -Name "Ethernet" -NewName "ETH1G"
    Write-Host "Renamed 'Ethernet' to 'ETH1G'"
} else {
    Write-Host "'Ethernet' adapter not found!"
}

# Rename "Ethernet 2" to "ETH10G"
if ($adapter2) {
    Rename-NetAdapter -Name "Ethernet 2" -NewName "ETH10G"
    Write-Host "Renamed 'Ethernet 2' to 'ETH10G'"
} else {
    Write-Host "'Ethernet 2' adapter not found!"
}