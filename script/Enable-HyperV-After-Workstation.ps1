# Re-enable Hyper-V stack & friends
dism /online /enable-feature /featurename:Microsoft-Hyper-V-All /all /norestart
dism /online /enable-feature /featurename:VirtualMachinePlatform /norestart
dism /online /enable-feature /featurename:WindowsHypervisorPlatform /norestart
dism /online /enable-feature /featurename:Containers-DisposableClientVM /norestart
# Optional: re-enable WSL
# dism /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /norestart

# Turn hypervisor back on at boot
bcdedit /set hypervisorlaunchtype auto

# Re-enable VBS/HVCI
New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" -Force | Out-Null
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard" -Name EnableVirtualizationBasedSecurity -Type DWord -Value 1
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" -Name Enabled -Type DWord -Value 1

Restart-Computer
