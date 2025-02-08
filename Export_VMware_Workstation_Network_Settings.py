import os
import subprocess
from datetime import datetime
import sys

# Parameters
VMWARE_DIR = r"C:\Program Files (x86)\VMware\VMware Workstation"
BACKUP_DIR = os.path.expanduser(r"C:\Users\Attila\Desktop\Code\cloudmigrationhu")
TIMESTAMP = datetime.now().strftime("%Y%m%d%H%M%S")
BACKUP_FILE = f"WS17_vnet_{TIMESTAMP}.dat"
BACKUP_PATH = os.path.join(BACKUP_DIR, BACKUP_FILE)

# Ensure the script is running as Administrator
def is_admin():
    try:
        return os.getuid() == 0  # UNIX-style admin check
    except AttributeError:
        # Windows admin check
        import ctypes
        return ctypes.windll.shell32.IsUserAnAdmin() != 0

if not is_admin():
    print("ERROR: This script must be run as Administrator.")
    print("Please restart the script with elevated privileges.")
    sys.exit(1)

# Confirm Backup
print(f"This script will export VMware virtual network settings to the following location:")
print(BACKUP_PATH)
confirm = input("Do you want to continue? (Y/N): ").strip().lower()

if confirm != 'y':
    print("Backup operation cancelled.")
    sys.exit()

# Create Backup Directory if It Doesn't Exist
if not os.path.exists(BACKUP_DIR):
    print(f"Creating backup directory: {BACKUP_DIR}")
    os.makedirs(BACKUP_DIR)

# Build the Command
vnetlib_exe = os.path.join(VMWARE_DIR, "vnetlib64.exe")
command = f'"{vnetlib_exe}" -- export {BACKUP_PATH}'

# Debug: Output the Command
print(f"Running the following command for export:")
print(command)

# Run the Command
try:
    result = subprocess.run(command, shell=True, check=True, text=True, capture_output=True)
    print(f"Backup completed successfully: {BACKUP_PATH}")
except subprocess.CalledProcessError as e:
    #print("ERROR: Failed to export VMware network settings.")
    #print("Verify the following command works manually:")
    print(command)
    #print(f"Error details:\n{e.stderr.strip()}")
    #sys.exit(1)

# End of Script
print("Script execution completed.")
