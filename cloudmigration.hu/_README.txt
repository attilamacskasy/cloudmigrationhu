1:25 AM 2/7/2025

These scripts have been tested on Windows Server 2022.

We are not using Windows Server 2025 yet because Synology VMM currently does not support NICs for Windows Server 2025 VMs, even when guest tools are installed.
Since we require these VMs to run continuously, we have located our domain controllers and file servers on Synology.

All other workloads are hosted in nested virtualization on Broadcom's VMware Workstation 17, as it is free and offers better performance than Hyper-V.
This is especially true when hardware access is enabled directly for the VMs :)

Thank you.
