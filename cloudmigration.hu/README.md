# Description of Scripts (Work in Progress)

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


**Next steps**


   In the future, this will evolve into a sleek, modern DevOps pipeline capable of redeploying the entire LAB with ease. However, due to the unique nature of this setup—built on Hyper-V, Synology, and Mikrotik—there are specific networking and hardware requirements that differ from standardized public cloud environments.
