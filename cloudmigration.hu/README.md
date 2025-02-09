## Getting Started - WARNING (outdated)

If you don’t have VMM or vCenter to execute in-guest configurations, this set of scripts will handle the setup for you.

### Steps:

1. **Set Execution Policy:**
   - We recommend running `000_Set-ExecutionPolicy_Bypass_CurrentUser.txt` for a persistent configuration.
   - Alternatively, you can use `000_Set-ExecutionPolicy_Bypass_Process.txt`, but keep in mind that this setting resets after every restart, requiring you to run it again.

2. **Review Configuration:**
   - Open `00_Server_Config.json` and adjust the settings as needed before proceeding.

3. **Automate Server Setup:**
   - Use `00_Automated_Script_Launcher.ps1` to apply the initial configuration on cloned VMs, especially after running `sysprep.exe`.

This approach ensures that your server deployments are consistent, automated, and ready for domain integration.

## Contents of the `cloudmigration.hu` Folder

The `cloudmigration.hu` folder contains a suite of PowerShell scripts and configuration files designed to automate and streamline the deployment and configuration of servers within the lab environment. Key components include:

- **Configuration Files:**
  - `00_Server_Config.json`: Defines server-specific settings such as computer names, IP addresses, subnet masks, default gateways, and DNS servers.

- **Execution Policy Scripts:**
  - `00_Set-ExecutionPolicy_Bypass_CurrentUser.txt`: Sets the PowerShell execution policy to bypass for the current user, ensuring scripts can run without restriction.
  - `00_Set-ExecutionPolicy_Bypass_Process.txt`: Temporarily sets the execution policy to bypass for the current process; this setting resets after each restart.

- **Automated Script Launcher:**
  - `00_Automated_Script_Launcher.ps1`: Orchestrates the execution of various configuration scripts to set up servers post-deployment.

- **Server Configuration Scripts:**
  - `01_Set_Computer_Name_and_IP_Address_2025.ps1`: Configures the computer name and network settings based on the details specified in `00_Server_Config.json`.
  - `02_Join_Computer_To_Domain.ps1`: Joins the server to the specified domain using credentials and domain information from the configuration file.

## How It Works

1. **Preparation:**
   - Ensure that the PowerShell execution policy allows script execution. Run `00_Set-ExecutionPolicy_Bypass_CurrentUser.txt` to set the policy for the current user persistently.

2. **Configuration:**
   - Edit `00_Server_Config.json` to specify the desired settings for each server, including names, IP configurations, and domain details.

3. **Execution:**
   - Run `00_Automated_Script_Launcher.ps1` to initiate the configuration process. This script will call the necessary subordinate scripts in sequence to apply the configurations defined in the JSON file.

4. **Server Naming and IP Configuration:**
   - `01_Set_Computer_Name_and_IP_Address_2025.ps1` reads the server's settings from `00_Server_Config.json` and applies the specified computer name and network configurations.

5. **Domain Joining:**
   - `02_Join_Computer_To_Domain.ps1` utilizes the domain information from the configuration file to join the server to the specified domain. The script prompts for the domain administrator's password during execution.

By following this structured approach, the `cloudmigration.hu` folder's scripts facilitate a streamlined and automated deployment process, ensuring consistency and reducing manual configuration efforts across the lab environment.
