4:35 PM 2/7/2025

If you don’t have VMM or vCenter to execute in-guest configurations, this set of scripts will handle the setup for you.

Getting Started:

1. Set Execution Policy:
   - We recommend running 00_Set-ExecutionPolicy_Bypass_CurrentUser.txt for a persistent configuration.
   - Alternatively, you can use 00_Set-ExecutionPolicy_Bypass_Process.txt, but keep in mind that this setting resets after every restart, requiring you to run it again.

2. Review Configuration:
   - Open 00_Server_Config.json and adjust the settings as needed before proceeding.

3. Automate Server Setup:
   - Use 00_Automated_Script_Launcher.ps1 to apply the initial configuration on cloned VMs, especially after running sysprep.exe.

This approach ensures that your server deployments are consistent, automated, and ready for domain integration.

WARNING: These scripts have been tested on Windows Server 2025 (only).
Currently, the scripts are not fully compatible with Windows Server 2022 (for Synology VMM support *) or Windows Server 2003 (for retro gaming server provisioning). 
Support for these versions is in progress, and some scripts are already prepared.
However, automation currently filters execution to "01_*_2025.ps1" scripts.

* we are not using Windows Server 2025 yet because Synology VMM currently does not support NICs for Windows Server 2025 VMs, even when guest tools are installed.
Since we require these VMs to run continuously, we have located our domain controllers and file servers on Synology.

All other workloads are hosted in nested virtualization on Broadcom's VMware Workstation 17, as it is free and offers better performance than Hyper-V.
This is especially true when hardware access is enabled directly for the VMs :)

Thank you.