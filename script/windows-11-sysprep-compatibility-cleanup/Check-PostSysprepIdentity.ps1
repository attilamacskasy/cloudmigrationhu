# File: Check-PostSysprepIdentity.ps1
<#
.SYNOPSIS
  Quick identity check after Sysprep to validate uniqueness.

.DESCRIPTION
  Displays:
    - MachineGuid (HKLM:\SOFTWARE\Microsoft\Cryptography\MachineGuid)
    - Hardware UUID (Win32_ComputerSystemProduct.UUID)
    - Computer name
    - Logged-on user
    - IPv4 addresses
#>

Write-Host "=== Post-Sysprep Identity Check ===" -ForegroundColor Cyan

# Computer name
$computerName = $env:COMPUTERNAME
Write-Host "`nComputer Name: " -NoNewline -ForegroundColor Yellow
Write-Host $computerName -ForegroundColor White

# Logged-on user
$currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
Write-Host "Logged-on User: " -NoNewline -ForegroundColor Yellow
Write-Host $currentUser -ForegroundColor White

# MachineGuid from registry
try {
    $regPath = 'HKLM:\SOFTWARE\Microsoft\Cryptography'
    $machineGuid = (Get-ItemProperty -Path $regPath -Name MachineGuid -ErrorAction Stop).MachineGuid
    Write-Host "`nMachineGuid (registry):" -ForegroundColor Yellow
    Write-Host "  $machineGuid" -ForegroundColor White
} catch {
    Write-Host "`nMachineGuid: FAILED to read ($($_.Exception.Message))" -ForegroundColor Red
}

# Hardware UUID from Win32_ComputerSystemProduct
try {
    $uuid = Get-CimInstance -ClassName Win32_ComputerSystemProduct |
            Select-Object -ExpandProperty UUID
    Write-Host "`nHardware UUID (Win32_ComputerSystemProduct.UUID):" -ForegroundColor Yellow
    Write-Host "  $uuid" -ForegroundColor White
} catch {
    Write-Host "`nHardware UUID: FAILED to read ($($_.Exception.Message))" -ForegroundColor Red
}

# IP addresses (IPv4, non-loopback)
try {
    $ipAddresses = Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
                   Where-Object { $_.IPAddress -ne '127.0.0.1' -and $_.IPAddress -notlike '169.254.*' }

    Write-Host "`nIPv4 Addresses:" -ForegroundColor Yellow

    if ($ipAddresses) {
        foreach ($ip in $ipAddresses) {
            Write-Host ("  {0,-15}  {1}" -f $ip.IPAddress, $ip.InterfaceAlias) -ForegroundColor White
        }
    } else {
        Write-Host "  (No active IPv4 addresses found)" -ForegroundColor DarkGray
    }
} catch {
    Write-Host "`nIPv4 Addresses: FAILED to enumerate ($($_.Exception.Message))" -ForegroundColor Red
}

Write-Host "`nCompare these values across VMs to ensure uniqueness." -ForegroundColor Cyan
Write-Host "=== Check complete ===" -ForegroundColor Cyan