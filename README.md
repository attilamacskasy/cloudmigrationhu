# CloudMigrationHU

## Authors

- [attilamacskasy](https://github.com/attilamacskasy)
- [peterkarpati0](https://github.com/peterkarpati0)

## Purpose

The **CloudMigrationHU** project aims to automate the setup and configuration of Windows Server 2022 domain controllers, specifically DC01 and DC02. The project provides PowerShell scripts to streamline tasks such as setting computer names, configuring IP addresses, and applying common server settings, ensuring a consistent and efficient deployment process.

## Architecture Diagram

```mermaid
graph TD;
    subgraph Network
        DC01[DC01<br>IP: 172.22.22.1<br>Subnet: 255.255.255.0<br>Gateway: 172.22.22.254]
        DC02[DC02<br>IP: 172.22.23.1<br>Subnet: 255.255.255.0<br>Gateway: 172.22.23.254]
    end
    DC01 --- DC02
```



