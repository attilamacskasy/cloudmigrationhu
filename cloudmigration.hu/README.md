# **CloudMigration.hu Automated Deployment Scripts**

## **Introduction**  

This repository contains a collection of PowerShell scripts designed to automate various aspects of infrastructure deployment (and cloud migration). These scripts facilitate the provisioning, configuration, and management of servers, networking, storage, and virtualization environments, ensuring consistency, efficiency, and reliability in IT operations.

The scripts cover a broad range of tasks, including:  

- **Server Configuration & Management**: Automate the setup of computer names, IP addresses, Active Directory roles, and general system configurations.
- **Hyper-V Virtualization**: Set up Hyper-V hosts, create virtual switches, and manage network adapters.
- **Networking**: Configure static IP addresses, rename network adapters, and disable IPv6 where necessary.
- **Storage & iSCSI**: Establish iSCSI connections, set up disk configurations, and connect to Synology NAS devices.
- **Failover Clustering**: Install, configure, and reset cluster nodes to enhance high availability.
- **Database & Application Deployment**: Perform unattended installations of SQL Server 2022 and SSMS.

Each script is designed to minimize manual intervention, reduce the risk of misconfigurations, and improve overall system deployment efficiency. These scripts are particularly useful in hybrid cloud environments, where Hyper-V, Synology NAS, and Mikrotik networking equipment are integrated.

## **How to Use These Scripts**
- Most scripts rely on predefined configurations stored in JSON files, ensuring a standardized and repeatable deployment process.
- Scripts should be executed with administrative privileges to ensure they can modify system settings as required.
- Logging mechanisms are included in many scripts, providing transparency and aiding in troubleshooting.

This collection is continuously evolving to incorporate best practices and automation improvements. Future enhancements will aim to replace manual deployment steps with a fully automated DevOps pipeline.

## **CloudMigration.hu Deployment Scripts Overview**

This table provides a summary of each script in the repository, including a brief description and an overview of its hardcoded parameters.

| **Filename**                                          | **Brief Summary** | **Hardcoded Parameters** |
|-------------------------------------------------------|------------------|-------------------------|
| **00_Automated_Script_Launcher.ps1**                 | Orchestrates and sequentially executes multiple scripts in the correct order. | No hardcoded parameters, dynamically calls scripts. |
| **00_Server_Config.json**                             | JSON configuration file storing global and server-specific settings. | Various server settings (e.g., TimeZone, NTPServer, Domain, IP addresses). |
| **00_Rename_NICs_on_NestedVirtualizationHost.ps1**   | Renames network adapters on a nested virtualization host based on predefined mappings. | No fixed mappings, dynamically fetches adapters. |
| **01_Set_Computer_Name_and_IP_Address_2025.ps1**     | Assigns a computer name and static IP address based on predefined JSON configuration. | Reads from `00_Server_Config.json`. |
| **02_Prepare_Generic_Configurations.ps1**            | Applies global system settings like time zone, NTP server, Remote Desktop, and firewall state. | Reads from `00_Server_Config.json`. |
| **03_Promote_First_Domain_Controller.ps1**           | Installs AD DS and promotes the first Domain Controller in a new AD forest. | `DomainName`, `NetBIOSName`, `InstallDNS`, `DatabasePath`, `LogPath`, `SysvolPath` (from config). |
| **04_Promote_Additional_Domain_Controller.ps1**      | Adds an additional Domain Controller to an existing AD domain. | `DomainName`, `InstallDNS`, `DatabasePath`, `LogPath`, `SysvolPath` (from config). |
| **05_Join_Computer_To_Domain.ps1**                   | Joins a Windows computer to an Active Directory domain. | `DomainName`, `OUPath` (from config). |
| **06_SQL_2022_Unattended_Deploy.ps1**                | Installs Microsoft SQL Server 2022 in unattended mode. | SQL instance name, SA password (prompted). |
| **07_SSMS-Unattended_Download_and_Deploy.ps1**       | Downloads and installs SQL Server Management Studio (SSMS). | `SSMS_Download_URL`, local file path for download. |
| **08_Reconfigure_HV_Cluster.ps1**                    | Reconfigures nested Hyper-V VMs running on VMware Workstation 17 by adjusting memory and CPU settings. | VM names, memory allocation, number of processors, and cores per processor. |
| **09_Install-WindowsFeature_Hyper-V.ps1**            | Installs the Hyper-V role and management tools on a Windows Server. | No user-defined parameters, installs `Hyper-V` role. |
| **10_Rename_NICs_on_Hyper-V.ps1**                    | Renames Hyper-V network adapters based on predefined IP mappings. | Static mappings of IP ranges to NIC names. |
| **11_Disable-IPv6-AllAdapters.ps1**                  | Disables IPv6 on all network adapters. | No configurable parameters. |
| **12_Set-ISCSI-IP.ps1**                              | Assigns a static IP address to iSCSI network adapters based on predefined host mappings. | Static IP assignments for `HV01`, `HV02`, `HV03`. |
| **13_Connect-Synology-iSCSI.ps1**                    | Connects a Hyper-V server to an iSCSI target on a Synology NAS. | `SynologyTargetIP`, `IQN` of the iSCSI target. |
| **14_Disk_Info.ps1**                                 | Retrieves detailed information about all online disks and volumes. | No configurable parameters. |
| **15_(ResetFailoverClusterNode).ps1**                | Removes a node from a Windows Failover Cluster and resets its configuration. | No configurable parameters. |
| **16_(InstallFailoverClustering).ps1**               | Installs the Failover Clustering feature on a Windows Server. | No configurable parameters. |
| **17_CreateExternalSwitch_on_Hyper-V_for_MGMNT.ps1** | Creates an external virtual switch for management traffic on a Hyper-V host. | `vSwitch-External-MGMT`, `NetworkAdapterName` (`Ethernet` or `VMNet0-MGMNT`), `AllowManagementOS=True`. |

---

## **Detailed script documentation**


**00_Server_Config.json**

   *Description*: This JSON configuration file defines both global and server-specific settings to standardize and automate the setup of servers within the migration environment. It serves as a centralized repository for configuration parameters, ensuring consistency across all deployed servers.

   *Functionality*: The file is structured into two main sections:

   - **GlobalConfig**: Contains settings applicable to all servers, including:
     - **TimeZone**: Specifies the time zone to be configured on each server (e.g., "Central Europe Standard Time").
     - **NTPServer**: Defines the Network Time Protocol server for time synchronization (e.g., "0.hu.pool.ntp.org").
     - **EnableRemoteDesktop**: A boolean value indicating whether Remote Desktop should be enabled.
     - **DisableFirewall**: A boolean value indicating whether the firewall should be disabled.
     - **IEEnhancedSecurityConfiguration**: Specifies the state ("On" or "Off") of Internet Explorer Enhanced Security Configuration for Administrators and Users.

   - **ServerSpecificConfig**: An array of objects, each representing individual server configurations, including:
     - **ServerName**: The designated name of the server.
     - **ComputerName**: The computer name to be assigned.
     - **IPAddress**: The static IP address to be configured.
     - **SubnetMask**: The subnet mask associated with the IP address.
     - **Gateway**: The default gateway for network traffic.
     - **DNSServers**: A list of DNS servers for name resolution.
     - **Domain**: The domain to which the server will be joined.
     - **Roles**: A list of server roles to be installed (e.g., "DNS", "DHCP").
     - **Features**: A list of server features to be enabled.
     - **AdditionalSettings**: Any other custom settings specific to the server.

   *Importance*: Utilizing this configuration file allows for automated, consistent, and repeatable server deployments. By defining settings in a centralized manner, it reduces manual configuration errors, ensures adherence to organizational standards, and streamlines the provisioning process. This approach is particularly beneficial in large-scale environments where uniformity and efficiency are paramount.

---

**00_Automated_Script_Launcher.ps1**

   *Description*: This script serves as a centralized orchestrator, designed to sequentially execute a series of migration-related scripts in a predefined order. It ensures that each step of the migration process is carried out systematically, reducing the potential for human error and streamlining the overall workflow.

   *Functionality*: Upon execution, the script:

   - Defines the sequence of scripts to be run, typically corresponding to various stages of the process.
   - Initiates each script in the specified order, monitoring their execution status.
   - Logs the outcome of each script, capturing success or failure states and any pertinent output messages.
   - Implements error-handling mechanisms to halt the process if a critical script fails, ensuring that subsequent steps are not executed under faulty conditions.

   *Importance*: By utilizing this automated launcher, organizations can ensure a consistent and repeatable deployment process. It minimizes manual intervention, reduces the likelihood of missed steps or misconfigurations, and provides a clear audit trail of the migration activities. This approach enhances efficiency, accountability, and overall success rates in cloud migration projects.


---

**00_Rename_NICs_on_NestedVirtualizationHost.ps1**

*Description*: This PowerShell script is designed to rename network adapters on a host configured for nested virtualization. By assigning meaningful names to the network interfaces, it enhances clarity and manageability, especially in complex virtualized environments.

*Functionality*: Upon execution, the script:

- Identifies all network adapters present on the host system.
- Applies a predefined naming convention to each adapter based on criteria such as adapter type, connection status, or MAC address.
- Updates the system configuration to reflect the new adapter names.

*Importance*: In environments utilizing nested virtualization, hosts may have multiple network adapters, making it challenging to manage and configure them effectively. By renaming the NICs to more descriptive names, administrators can:

- Easily identify and differentiate between various network interfaces.
- Reduce the risk of configuration errors related to network settings.
- Simplify troubleshooting and maintenance tasks by providing clear and consistent adapter identifiers.

Implementing this script contributes to a more organized and efficient management of network resources within nested virtualization hosts.

---

**01_Set_Computer_Name_and_IP_Address_2025.ps1**

There will be different version for Windows Server 2022 and Windows Server 2003 R2. Probably there will be no such script for DOS 6.22 :-)

*Description*: This PowerShell script is designed to automate the configuration of a server's computer name and IP address settings, streamlining the initial setup process in a standardized manner. 

*Functionality*: Upon execution, the script:

- Accepts a mandatory parameter, **ServerName**, which specifies the target server's name.
- Loads configuration details from the `00_Server_Config.json` file to retrieve the corresponding settings for the specified server.
- Validates the presence of the configuration file and the specified server's configuration within it.
- Sets the computer name to the value defined in the configuration file.
- Configures the network adapter with the specified static IP address, subnet mask, gateway, and DNS servers.
- Optionally, prompts for domain credentials and joins the server to the specified domain if domain information is provided.

*Importance*: Automating the assignment of computer names and IP addresses ensures consistency across server deployments, reduces manual configuration errors, and accelerates the provisioning process. This script is particularly useful in environments where multiple servers are being deployed, as it enforces standardized naming conventions and network settings, thereby enhancing manageability and reducing the potential for misconfigurations.

---

**02_Prepare_Generic_Configurations.ps1**

*Description*: This PowerShell script automates the application of global configuration settings to a server, ensuring consistency across the environment. It reads from a predefined JSON configuration file and applies settings such as time zone, NTP server, Remote Desktop availability, firewall status, and Internet Explorer Enhanced Security Configuration.

*Functionality*: Upon execution, the script:

- Loads the `00_Server_Config.json` file to retrieve global configuration parameters.
- Validates the presence of the `GlobalConfig` section within the configuration file.
- Extracts settings including:
  - **TimeZone**: Sets the system's time zone.
  - **NTPServer**: Configures the Network Time Protocol server for time synchronization.
  - **EnableRemoteDesktop**: Enables or disables Remote Desktop access based on the specified boolean value.
  - **DisableFirewall**: Turns the Windows Firewall on or off as indicated.
  - **IEEnhancedSecurityConfiguration**: Adjusts Internet Explorer Enhanced Security Configuration settings for administrators and users.
- Applies each of these settings to the server, ensuring alignment with the defined global configurations.

*Importance*: By automating the application of generic configurations, this script ensures that all servers within the environment adhere to a standardized setup. This consistency reduces the likelihood of configuration drift, enhances security by enforcing uniform settings, and simplifies management by providing a repeatable process for configuring servers.

---

**03_Promote_First_Domain_Controller.ps1**

*Description*: This PowerShell script automates the promotion of a Windows Server to the first Domain Controller (DC) in a new Active Directory (AD) forest. It streamlines the initial setup of an AD environment by configuring the necessary roles and services.

*Functionality*: Upon execution, the script:

- Loads configuration parameters from the `00_Server_Config.json` file, specifically from the `DomainPromotionConfig` section.
- Validates the presence of required configuration settings, including:
  - **DomainName**: The fully qualified domain name (FQDN) for the new AD forest.
  - **NetBIOSName**: The NetBIOS name for the domain.
  - **InstallDNS**: A boolean indicating whether to install the DNS Server service.
  - **DatabasePath**, **LogPath**, **SysvolPath**: Paths for the AD database, log files, and SYSVOL directory, respectively.
- Installs the Active Directory Domain Services (AD DS) role if not already present.
- Promotes the server to a Domain Controller by:
  - Creating a new AD forest with the specified domain name.
  - Configuring the DNS Server service if specified.
  - Setting the AD database, log, and SYSVOL paths as per the configuration.
  - Specifying the Directory Services Restore Mode (DSRM) password.
- Restarts the server upon successful promotion to apply changes.

*Importance*: Establishing the first Domain Controller is a critical step in setting up an Active Directory environment. This script ensures that the process is performed consistently and accurately by:

- Automating the installation and configuration of AD DS and DNS roles.
- Reducing the potential for human error during the promotion process.
- Ensuring that all necessary configurations are applied uniformly across deployments.

By using this script, administrators can efficiently set up the foundational AD infrastructure, paving the way for subsequent domain controllers and member servers to join the domain.

---

**04_Promote_Additional_Domain_Controller.ps1**

*Description*: This PowerShell script automates the promotion of an existing Windows Server to an additional Domain Controller (DC) within an existing Active Directory (AD) domain. It streamlines the process of enhancing directory service availability and load balancing by adding redundancy to the AD infrastructure.

*Functionality*: Upon execution, the script:

- Loads configuration parameters from the `00_Server_Config.json` file, specifically from the `DomainPromotionConfig` section.
- Validates the presence of required configuration settings, including:
  - **DomainName**: The fully qualified domain name (FQDN) of the existing AD domain.
  - **InstallDNS**: A boolean indicating whether to install the DNS Server service on the additional DC.
  - **DatabasePath**, **LogPath**, **SysvolPath**: Paths for the AD database, log files, and SYSVOL directory, respectively.
- Installs the Active Directory Domain Services (AD DS) role if not already present.
- Promotes the server to an additional Domain Controller by:
  - Joining the existing AD domain specified by `DomainName`.
  - Configuring the DNS Server service if specified.
  - Setting the AD database, log, and SYSVOL paths as per the configuration.
  - Specifying the Directory Services Restore Mode (DSRM) password.
- Restarts the server upon successful promotion to apply changes.

*Importance*: Adding additional Domain Controllers to an existing AD domain is crucial for:

- **Redundancy**: Ensuring high availability of directory services by providing backup in case one DC fails.
- **Load Balancing**: Distributing authentication and directory lookup requests to improve performance.
- **Geographical Distribution**: Placing DCs in different locations to serve local users more efficiently.

By automating this process, the script ensures consistency in DC deployments, reduces manual effort, and minimizes the risk of configuration errors, thereby maintaining the integrity and reliability of the AD environment.

---

**05_Join_Computer_To_Domain.ps1**

*Description*: This PowerShell script automates the process of joining a Windows computer to an Active Directory (AD) domain, streamlining the integration of new machines into the domain environment.

*Functionality*: Upon execution, the script:

- Loads configuration settings from the `00_Server_Config.json` file to retrieve domain join parameters.
- Validates the presence of necessary configuration data, including:
  - **DomainName**: The fully qualified domain name (FQDN) of the AD domain to join.
  - **OUPath**: The distinguished name (DN) of the Organizational Unit (OU) where the computer account should be created.
- Prompts for domain credentials with sufficient privileges to join computers to the domain.
- Attempts to join the computer to the specified domain and move it to the designated OU.
- Logs the outcome of the domain join operation, indicating success or failure.

*Importance*: Joining computers to an AD domain is a fundamental task in enterprise environments, providing centralized management, security policies, and resource access. Automating this process ensures:

- **Consistency**: Uniform application of domain join settings across multiple machines.
- **Efficiency**: Reduced manual effort and time required to add computers to the domain.
- **Accuracy**: Minimized risk of errors associated with manual domain joining procedures.

By utilizing this script, administrators can efficiently integrate new computers into the AD domain, maintaining organizational standards and enhancing overall network management.

---

**06_SQL_2022_Unattended_Deploy.ps1**

*Description*: This PowerShell script automates the unattended installation of Microsoft SQL Server 2022 Standard Edition. It streamlines the deployment process by mounting the SQL Server ISO, configuring installation parameters, and executing the setup without manual intervention.

*Functionality*: Upon execution, the script:

- **Mounts the SQL Server ISO**: Locates the ISO file on the user's desktop and mounts it to a virtual drive.
- **Defines installation parameters**: Sets up configuration parameters such as instance name, feature selection, and authentication mode.
- **Prompts for SA password**: Securely prompts the user to input a password for the SQL Server system administrator (SA) account.
- **Initiates the installation**: Runs the SQL Server setup executable with the specified parameters in unattended mode.
- **Logs the installation process**: Generates a log file to capture the details and outcome of the installation.

*Importance*: Automating the SQL Server installation ensures consistency across deployments, reduces the potential for human error, and saves time. This script is particularly useful in environments where multiple SQL Server instances are deployed, as it enforces standardized configurations and streamlines the setup process.

---

**07_SSMS-Unattended_Download_and_Deploy.ps1**

*Description*: This PowerShell script automates the download and installation of SQL Server Management Studio (SSMS), providing a streamlined approach to setting up SSMS without manual intervention.

*Functionality*: Upon execution, the script:

- **Defines Variables**: Sets the URL for the SSMS installer and specifies the temporary path for the download.
- **Downloads SSMS Installer**: Utilizes the `Start-BitsTransfer` cmdlet to download the SSMS installer from the official Microsoft source to the designated temporary path.
- **Verifies Download**: Checks if the installer has been successfully downloaded; if not, it outputs an error message and exits.
- **Installs SSMS Silently**: Initiates the SSMS installation with silent parameters (`/install`, `/quiet`, `/norestart`) to ensure an unattended setup.
- **Confirms Installation**: Evaluates the success of the installation process and provides corresponding success or error messages.
- **Cleans Up**: Removes the downloaded installer from the temporary path to free up space and maintain cleanliness.

*Importance*: Automating the deployment of SSMS ensures a consistent installation process across multiple environments, reduces manual effort, and minimizes the risk of human error. This script is particularly beneficial for administrators and DevOps professionals who require a reliable and repeatable method to install SSMS in various setups.

---

**08_Reconfigure_HV_Cluster.ps1**

*Description*:  
This PowerShell script automates the reconfiguration of nested Hyper-V virtual machines (VMs) running within VMware Workstation 17. It adjusts the memory and processor settings of specified VMs to optimize resource allocation based on predefined configurations.

*Functionality*:  
Upon execution, the script performs the following steps:

1. **Define VM Configuration Options**:  
   Specifies a list of VMs along with their desired memory and processor configurations.

2. **Iterate Through Each VM**:  
   For each VM in the configuration list:
   - **Check VM State**:  
     Determines if the VM is currently running.
   - **Stop VM if Running**:  
     Gracefully shuts down the VM if it is active to allow for configuration changes.
   - **Modify VM Settings**:  
     Adjusts the VM's memory allocation, number of processors, and cores per processor as specified.
   - **Start VM**:  
     Restarts the VM after applying the new configurations.

3. **Logging**:  
   Records the actions taken for each VM, including any errors encountered during the process.

*Configuration Options*:  
The script utilizes a predefined list of VM configurations, specifying the desired memory and processor settings for each VM.


| **Option**  | **Memory** | **Processors** | **Cores Per Processor** |
|------------|-----------|--------------|----------------------|
| **1 - Small**  | 8 GB      | 1            | 1                    |
| **2 - Medium** | 16 GB     | 2            | 2                    |
| **3 - Large**  | 32 GB     | 4            | 4                    |

*Default*:  

| **VM Name** | **Memory (MB)** | **Processors** | **Cores Per Processor** |
|-------------|-----------------|----------------|-------------------------|
| `HV01`      | 8192            | 2              | 1                       |
| `HV02`      | 8192            | 2              | 1                       |
| `HV03`      | 8192            | 2              | 1                       |

*Importance*:  
Adjusting the resource allocation of nested Hyper-V VMs is crucial for:

- **Performance Optimization**: Ensuring that each VM has sufficient resources to perform its tasks efficiently without overcommitting the host system.

- **Resource Management**: Balancing the distribution of CPU and memory resources among multiple VMs to prevent any single VM from monopolizing system resources.

- **Scalability**: Allowing for dynamic adjustment of VM configurations to meet changing workload demands.

By automating this reconfiguration process, the script reduces manual effort, minimizes the risk of configuration errors, and ensures consistency across multiple VMs.

*Note*:  
Before executing this script, ensure that all VMs are in a state that allows for configuration changes and that the host system has adequate resources to accommodate the specified configurations. It is advisable to back up VM configurations prior to making changes.

---

**09_Install-WindowsFeature_Hyper-V.ps1**

*Description*: This PowerShell script automates the installation of the Hyper-V role and its management tools on a Windows Server 2025 machine. It ensures that the server is configured to support virtualization workloads by enabling the necessary features.

*Functionality*: Upon execution, the script:

- **Checks for Administrative Privileges**: Verifies that the script is running with administrative rights, which are required for feature installation.
- **Installs Hyper-V Feature**: Utilizes the `Install-WindowsFeature` cmdlet to add the Hyper-V role along with management tools.
- **Prompts for Restart**: Notifies the user that a system restart is necessary to complete the installation and prompts for confirmation to proceed with the reboot.

*Importance*: Automating the installation of Hyper-V ensures a consistent and efficient setup process, reducing the potential for human error. This script is particularly useful for administrators preparing servers for virtualization tasks, as it streamlines the deployment of the Hyper-V role and ensures that all necessary components are properly configured.

*Note*: If an error occurs stating, "Hyper-V cannot be installed: The processor does not have required virtualization capabilities," it may be necessary to enable nested virtualization on your host platform (e.g., VMware Workstation, vSphere, or Hyper-V).

---

**10_Rename_NICs_on_Hyper-V.ps1**

*Description*:  
This PowerShell script automates the renaming of network adapters on a Hyper-V host to align with predefined naming conventions based on their IP address ranges. This enhances clarity and manageability of network configurations within the Hyper-V environment.

*Functionality*:  
Upon execution, the script:

- **Defines Adapter Mappings**: Establishes a list of mappings that associate specific IP address ranges with corresponding VMnet IDs and acronyms.
- **Retrieves Network Adapters**: Gathers all network adapters present on the Hyper-V host.
- **Assigns New Names**: For each adapter, the script:
  - Retrieves the IP address and subnet mask.
  - Calculates the network address.
  - Matches the network address against the predefined adapter mappings.
  - If a match is found, constructs a new name using the VMnet ID and acronym (e.g., `"VMnet0-MGMNT"`) and renames the adapter accordingly.
- **Logs Results**: Outputs the original and new names of the network adapters, along with their IP addresses, for verification purposes.

*Hyper-V Host NIC Configuration*:

| NIC Number | Link Speed | Settings in VMware Workstation | vmnet ID | Purpose               | Acronym | Description                                           | IP Range         | VLAN |
|------------|------------|--------------------------------|----------|-----------------------|---------|-----------------------------------------------------|------------------|------|
| NIC 1      | 1 Gbps     | Bridged (LAB access on LAN)   | VMnet0   | Management            | MGMNT   | Used for host management and Hyper-V administration | 172.22.22.0/24   | n/a  |
| NIC 2      | 1 Gbps     | Host-only                     | VMnet1   | Live Migration        | LVMIG   | Dedicated for VM live migration between hosts       | 192.168.1.0/24   | n/a  |
| NIC 3      | 1 Gbps     | Host-only                     | VMnet2   | Cluster Communication | CLNET   | Private cluster network for heartbeats and traffic  | 192.168.2.0/24   | n/a  |
| NIC 4      | 10 Gbps    | Bridged (Synology 10G iSCSI)  | VMnet10  | Storage (iSCSI)       | ISCSI   | iSCSI traffic for shared storage access             | 192.168.22.0/24  | n/a  |
| NIC 5      | 1 Gbps     | Host-only                     | VMnet3   | VM Traffic (Internal) | VMINT   | Internal VM communication without external access   | 192.168.3.0/24   | n/a  |
| NIC 6      | 1 Gbps     | NAT                           | VMnet8   | VM Traffic (External) | VMEXT   | Provides internet access to VMs                    | 192.168.0.0/24   | n/a  |
| NIC 7      | 1 Gbps     | Host-only                     | VMnet4   | Backup Network        | BACKP   | Dedicated network for backup operations            | 192.168.4.0/24   | n/a  |

*Predefined Adapter Mappings*:
The script uses the following hardcoded mappings to determine the adapter names:

| **IP Range**       | **VMnet ID** | **Acronym** |
|--------------------|-------------|------------|
| 172.22.22.0/24    | VMnet0       | MGMNT      |
| 192.168.1.0/24    | VMnet1       | LVMIG      |
| 192.168.2.0/24    | VMnet2       | CLNET      |
| 192.168.22.0/24   | VMnet10      | ISTOR      |
| 192.168.3.0/24    | VMnet3       | VMINT      |
| 192.168.0.0/24    | VMnet8       | VMEXT      |
| 192.168.4.0/24    | VMnet4       | BACKP      |

*Importance*:  
In Hyper-V environments with multiple network adapters, having a clear and consistent naming convention is crucial for:

- **Simplified Management**: Easier identification and configuration of network interfaces.
- **Reduced Errors**: Minimizing the risk of misconfiguring network settings due to ambiguous adapter names.
- **Enhanced Documentation**: Providing clear references in documentation and during troubleshooting.

By automating the renaming process, this script ensures that network adapters are consistently named according to their designated roles and IP address ranges, thereby improving the overall manageability of the Hyper-V host's networking setup.

---

**11_Disable-IPv6-AllAdapters.ps1**

*Description*:  
This PowerShell script disables the IPv6 protocol across all network adapters on a Windows Server 2025 system. It ensures that IPv6 is turned off for each adapter, which can be necessary in environments where IPv6 is not utilized or could cause compatibility issues.

*Functionality*:  
Upon execution, the script:

- **Requires Administrative Privileges**: Ensures the script is run with the necessary permissions to modify network adapter settings.

- **Creates a Log File**: Generates a log file named `DisableIPv6Log.txt` on the user's desktop to record the script's actions and outcomes.

- **Defines Helper Functions**:
  - `MyLogMessage`: Logs messages to both the console and the log file.
  - `Get-AdapterInfo`: Retrieves detailed information about network adapters that are currently active, including their name, link speed, IP addresses, and interface index.

- **Disables IPv6**:
  - Iterates through all network adapters that are in an "Up" status.
  - For each adapter, sets the IPv6 setting to `Disabled` using the `Set-NetAdapterBinding` cmdlet.
  - Logs the success or failure of each operation, including any error messages encountered during the process.

*Importance*:  
Disabling IPv6 can be crucial in certain network environments where:

- **Compatibility**: Some applications or services may not support IPv6, leading to potential connectivity issues.

- **Security**: If IPv6 is not properly managed, it could introduce security vulnerabilities.

- **Network Policy**: Organizational policies might mandate the use of IPv4 exclusively.

By automating the disabling of IPv6 across all network adapters, this script ensures consistency and reduces the administrative effort required to manually configure each adapter. The logging functionality provides transparency and aids in troubleshooting by documenting the actions taken and any issues encountered during execution.

---

**12_Set-ISCSI-IP.ps1**

*Description*:  
This PowerShell script automates the configuration of iSCSI network settings on Hyper-V hosts by assigning predefined static IP addresses to the network adapters designated for iSCSI traffic. It ensures that each host is correctly configured to communicate with iSCSI storage devices, such as a Synology NAS.

*Functionality*:  
Upon execution, the script:

- **Defines iSCSI IP Mappings**: Establishes a mapping between Hyper-V hostnames and their corresponding iSCSI IP addresses:

  | Hostname | iSCSI IP Address |
  |----------|------------------|
  | HV01     | 192.168.22.65    |
  | HV02     | 192.168.22.66    |
  | HV03     | 192.168.22.67    |

- **Sets Default Gateway**: Specifies the default gateway IP address for the iSCSI network, typically the IP of the Synology NAS (e.g., `192.168.22.253`).

- **Retrieves Hostname**: Obtains the current server's hostname to determine the appropriate iSCSI IP address from the predefined mappings.

- **Configures Network Adapter**: Identifies the network adapter intended for iSCSI traffic and assigns the corresponding static IP address, subnet mask (defaulted to `255.255.255.0`), and default gateway.

- **Logs Actions**: Creates a log file on the desktop named `SetISCSIIPLog.txt` to record the script's actions and outcomes for auditing and troubleshooting purposes.

*Importance*:  
Proper configuration of iSCSI network settings is crucial for:

- **Storage Connectivity**: Ensuring reliable communication between Hyper-V hosts and iSCSI storage devices.

- **Performance Optimization**: Assigning dedicated network resources for storage traffic to prevent congestion and enhance performance.

- **Consistency**: Standardizing network configurations across multiple hosts to simplify management and reduce the risk of misconfigurations.

By automating the assignment of iSCSI IP addresses, this script reduces manual effort, minimizes the potential for errors, and ensures that each Hyper-V host is correctly configured to access iSCSI storage resources.

---

**13_Connect-Synology-iSCSI.ps1**

*Description*:  
This PowerShell script facilitates the connection between a Hyper-V server and a pre-configured iSCSI target on a Synology NAS. Due to limitations in automating iSCSI target configuration via Synology's REST API or remote SSH commands, the iSCSI target must be manually set up on the Synology NAS prior to executing this script.

*Functionality*:  
Upon execution, the script performs the following steps:

1. **Ensure iSCSI Initiator Service is Running**:  
   Verifies that the Microsoft iSCSI Initiator Service (`MSiSCSI`) is active on the Hyper-V server. If the service is not running, the script attempts to start it.

2. **Add Synology iSCSI Target Portal**:  
   Adds the IP address of the Synology NAS as an iSCSI target portal using the `New-IscsiTargetPortal` cmdlet.

3. **Discover Available iSCSI Targets**:  
   Discovers iSCSI targets available on the specified portal by invoking the `Get-IscsiTarget` cmdlet.

4. **Connect to the iSCSI Target**:  
   Establishes a connection to the specified iSCSI target using the `Connect-IscsiTarget` cmdlet, referencing the target's iSCSI Qualified Name (IQN).

*Configuration Parameters*:  
The script requires the following user-defined parameters:

- **$SynologyTargetIP**: The IP address of the Synology NAS (e.g., `"172.22.22.253"`).

- **$IQN**: The iSCSI Qualified Name of the target (e.g., `"iqn.2000-01.com.synology:nas1.default-target.53a7d83343b"`).

*Importance*:  
Connecting a Hyper-V server to an iSCSI target on a Synology NAS is essential for:

- **Expanding Storage Capacity**: Utilizing network-attached storage to increase available storage for virtual machines.

- **Centralized Storage Management**: Consolidating storage resources for easier management and backup.

- **High Availability**: Providing a reliable storage solution that can be accessed by multiple Hyper-V hosts.

By automating the connection process, this script reduces manual configuration efforts, minimizes the risk of errors, and ensures a consistent setup across Hyper-V environments.

*Note*: Prior to running this script, ensure that the iSCSI target is properly configured on the Synology NAS, as the script does not handle target creation or configuration.

---

**14_Disk_Info.ps1**

*Description*:  
This PowerShell script provides a comprehensive overview of all online disks and their associated volumes on a Windows system. It gathers detailed information such as disk size, filesystem type, allocation unit size, free space, percentage of used space, and drive letters.

*Functionality*:  
Upon execution, the script performs the following steps:

1. **Define Function to Retrieve Allocation Unit Size**:  
   A helper function, `Get-AllocationUnitSize`, is defined to determine the allocation unit size (cluster size) for a given drive letter using the `fsutil` utility.

2. **Retrieve Online Disks**:  
   Utilizes the `Get-Disk` cmdlet to fetch all disks with an operational status of "Online".

3. **Retrieve Volumes**:  
   Employs the `Get-Volume` cmdlet to obtain all volumes that have a filesystem associated with them.

4. **Gather Disk and Volume Information**:  
   For each online disk, the script:
   - Retrieves associated partitions using the `Get-Partition` cmdlet.
   - For each partition, matches it with the corresponding volume.
   - Collects and calculates the following details:
     - **Disk Number**: Identifier of the disk.
     - **Partition Number**: Identifier of the partition.
     - **Drive Letter**: Assigned drive letter, if available.
     - **File System**: Type of filesystem (e.g., NTFS, ReFS).
     - **Allocation Unit Size**: Size of each allocation unit in bytes.
     - **Size (GB)**: Total size of the volume in gigabytes.
     - **Free Space (GB)**: Available free space in gigabytes.
     - **% Used**: Percentage of space utilized.

5. **Display Results**:  
   Outputs the collected information in a formatted table for easy analysis.

*Importance*:  
Having detailed insights into disk and volume configurations is crucial for system administrators to:

- **Monitor Storage Utilization**: Identify disks or volumes nearing capacity to plan for upgrades or maintenance.

- **Optimize Performance**: Assess allocation unit sizes to ensure they align with workload requirements, potentially improving disk performance.

- **Maintain System Health**: Regularly review disk statuses to preemptively detect and address potential issues.

By automating the collection of this information, the script aids in efficient system management and informed decision-making regarding storage resources.

---

**15_(ResetFailoverClusterNode).ps1**

!!! NOT USED EXPERIMENTAL !!!

*Description*:  
This PowerShell script is designed to reset a node in a Windows Failover Cluster by removing all cluster-related configurations and features from the specified node. This process is useful when a cluster node needs to be reconfigured or removed from the cluster environment.

*Functionality*:  
Upon execution, the script performs the following steps:

1. **Define the Node to Reset**:  
   Sets the `$NodeName` variable to the name of the local computer (`$env:COMPUTERNAME`), indicating that the script targets the node on which it is run.

2. **Stop the Cluster Service**:  
   Attempts to stop the Cluster Service (`ClusSvc`) on the node using the `Stop-Service` cmdlet with the `-Force` parameter to ensure termination.

3. **Uninstall Failover Clustering Feature**:  
   Removes the Failover Clustering feature from the node by invoking the `Uninstall-WindowsFeature` cmdlet with the `-Name Failover-Clustering` parameter.

4. **Clear Cluster Configuration Files**:  
   Deletes the contents of the `C:\Windows\Cluster` directory, which contains cluster configuration files, using the `Remove-Item` cmdlet with the `-Recurse` and `-Force` parameters.

5. **Remove Cluster-Related Registry Entries**:  
   Checks for the existence of the `HKLM:\SYSTEM\CurrentControlSet\Services\ClusSvc` registry path and, if present, removes it using the `Remove-Item` cmdlet with the `-Recurse` and `-Force` parameters.

*Importance*:  
Resetting a cluster node is a critical maintenance task that may be necessary in scenarios such as:

- **Node Decommissioning**: Safely removing a node from the cluster before decommissioning or repurposing the hardware.

- **Reconfiguration**: Clearing existing cluster configurations to prepare the node for reconfiguration or addition to a different cluster.

- **Troubleshooting**: Eliminating corrupted or inconsistent cluster settings that may be causing issues within the cluster.

By automating the reset process, this script ensures that all cluster-related components are thoroughly removed, reducing the risk of residual configurations causing future conflicts. It streamlines the task, minimizes human error, and ensures consistency across multiple nodes when necessary.

*Note*: This script should be executed with caution, as it will remove all cluster configurations from the node. It is recommended to ensure that the node is no longer needed in the cluster or that a backup of the configuration is available if required.

---

**16_(InstallFailoverClustering).ps1**

!!! NOT USED EXPERIMENTAL !!!

*Description*:  
This PowerShell script is designed to install and configure the Failover Clustering feature on a Windows Server. It automates the setup process to prepare the server as a node within a failover cluster environment.

*Functionality*:  
Upon execution, the script performs the following steps:

1. **Identify the Local Machine**:  
   Retrieves the name of the local computer using the `$env:COMPUTERNAME` environment variable and assigns it to the `$NodeName` variable.

2. **Install Failover Clustering Feature**:  
   Utilizes the `Install-WindowsFeature` cmdlet to install the Failover Clustering feature, including management tools, on the local server.

3. **Configure Cluster Service**:  
   Sets the Cluster Service (`ClusSvc`) to start automatically by using the `Set-Service` cmdlet with the `-StartupType Automatic` parameter.

4. **Start Cluster Service**:  
   Attempts to start the Cluster Service using the `Start-Service` cmdlet.

5. **Verify Service Status**:  
   Checks the status of the Cluster Service to confirm it is running. If the service is running, it outputs a success message; otherwise, it logs an error message.

*Importance*:  
Setting up Failover Clustering is essential for creating a high-availability environment, allowing multiple servers to work together to provide continuous service availability. By automating the installation and configuration process, this script ensures consistency across cluster nodes, reduces manual effort, and minimizes the potential for configuration errors.

*Note*:  
The script includes a warning indicating that it is experimental and that the author has traditionally used the Windows GUI for creating failover clusters due to the complexity of required validations and configurations. The script aims to automate this process using PowerShell, but users should proceed with caution and thoroughly test in a controlled environment before deploying in production.

---

**17_Create_External_Switch_on_Hyper-V_for_MGMNT.ps1**

*Description*:  
This PowerShell script automates the creation of an external virtual switch on a Hyper-V host, specifically for management purposes. It ensures that the virtual switch is properly configured and associated with the designated physical network adapter, facilitating network connectivity for virtual machines and management operations.

*Functionality*:  
Upon execution, the script performs the following steps:

1. **Define Parameters**:  
   Sets the name of the virtual switch and the physical network adapter to be used.

2. **Check for Existing Virtual Switch**:  
   Utilizes the `Get-VMSwitch` cmdlet to determine if a virtual switch with the specified name already exists.

3. **Create Virtual Switch**:  
   If the virtual switch does not exist, the script:
   - Retrieves the physical network adapter using the `Get-NetAdapter` cmdlet.
   - Validates that the network adapter is found and is in an "Up" state.
   - Creates the external virtual switch using the `New-VMSwitch` cmdlet, associating it with the specified network adapter and enabling device management.

4. **Output Status**:  
   Provides console output indicating the success or failure of the virtual switch creation process.

*Hardcoded Parameters*:  
The script uses the following predefined parameters:

| Parameter Name         | Value                   | Description |
|------------------------|------------------------|-------------|
| **$VirtualSwitchName** | `vSwitch-External-MGMT` | The name of the external virtual switch to be created. |
| **$NetworkAdapterName** | `Ethernet` or `VMNet0-MGMNT` | The physical network adapter that the virtual switch will be bound to. |
| **$AllowManagementOS** | `True` | Specifies whether the management OS should have access to the external network via the virtual switch. |

*Importance*:  
Creating an external virtual switch on a Hyper-V host is essential for:

- **Network Connectivity**: Allowing virtual machines to communicate with external networks and resources.
- **Management Operations**: Facilitating remote management and access to virtual machines and the host system.

By automating this process, the script ensures consistency in virtual switch configurations across multiple Hyper-V hosts, reduces manual effort, and minimizes the potential for configuration errors.

*Note*:  
Executing this script on a remote desktop session may cause a temporary network disconnect, as the network adapter is reconfigured during virtual switch creation. It is advisable to run this script during a maintenance window or when such a disruption will have minimal impact.

**Next steps**


   In the future, this will evolve into a sleek, modern DevOps pipeline capable of redeploying the entire LAB with ease. However, due to the unique nature of this setup—built on Hyper-V, Synology, and Mikrotik—there are specific networking and hardware requirements that differ from standardized public cloud environments.
