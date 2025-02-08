# Hyper-V Host Network Configuration for CloudMigration.hu LAB

The CloudMigration.hu LAB is designed to be a state-of-the-art multi-site lab environment that showcases enterprise-inspired hybrid and multi-cloud architectures. It integrates a mix of legacy systems and modern virtualization technologies, leveraging Hyper-V and VMware Workstation for virtualization. This setup aligns with Microsoft's Cloud Adoption Framework and is tailored to demonstrate real-world cloud migration, modernization strategies, and hybrid cloud designs.

The following table outlines the recommended NIC configuration for a Hyper-V host in this lab setup. Each NIC serves a specific purpose, ensuring optimal performance, redundancy, and segregation of network traffic to support various workloads and management tasks. This configuration also integrates Synology NAS devices for storage and provides seamless connectivity across lab components.

## Hyper-V Host NIC Configuration

| NIC Number | Link Speed | Settings in VMware Workstation | vmnet ID | Purpose               | Description                                           | IP Range         | VLAN |
|------------|------------|--------------------------------|----------|-----------------------|-----------------------------------------------------|------------------|------|
| NIC 1      | 1 Gbps     | Bridged (LAB access on LAN)   | VMnet0   | Management            | Used for host management and Hyper-V administration | 172.22.22.0/24   | n/a  |
| NIC 2      | 1 Gbps     | Host-only                     | VMnet1   | Live Migration        | Dedicated for VM live migration between hosts       | 192.168.1.0/24   | n/a  |
| NIC 3      | 1 Gbps     | Host-only                     | VMnet2   | Cluster Communication | Private cluster network for heartbeats and traffic  | 192.168.2.0/24   | n/a  |
| NIC 4      | 10 Gbps    | Bridged (Synology 10G iSCSI)  | VMnet10  | Storage (iSCSI)       | iSCSI traffic for shared storage access             | 192.168.22.0/24  | n/a  |
| NIC 5      | 1 Gbps     | Host-only                     | VMnet3   | VM Traffic (Internal) | Internal VM communication without external access   | 192.168.3.0/24   | n/a  |
| NIC 6      | 1 Gbps     | NAT                           | VMnet8   | VM Traffic (External) | Provides internet access to VMs                    | 192.168.0.0/24   | n/a  |
| NIC 7      | 1 Gbps     | Host-only                     | VMnet4   | Backup Network        | Dedicated network for backup operations            | 192.168.4.0/24   | n/a  |

This configuration reflects best practices for Hyper-V networking, ensuring reliable connectivity and efficient resource utilization. Each NIC is mapped to a specific VMnet in VMware Workstation to provide isolation and align with the lab's multi-cloud and hybrid cloud objectives.
