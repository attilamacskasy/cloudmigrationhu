# Cloudmigration.hu - effort to deploy the best possible multi-cloud/hybrid lab

## Purpose

Our mission at CloudMigration.hu LAB is to establish a state-of-the-art, enterprise-inspired multi-site laboratory that leverages Microsoft's best practices for on-premises setups and the Cloud Adoption Framework for cloud environments.

Our lab serves as a comprehensive showcase of the vast expertise accumulated throughout my career, featuring everything from retro computing systems running DOS 6.22, Windows 98, XP, 7, up to the latest Windows 11.

On the server side, we've implemented essential infrastructure components including domain controllers, databases, file servers, application servers, with added redundancy in NAS, and uniform appliance-based gateways across on-premises and cloud platforms.

Our cloud strategy extends to major hyperscalers like Azure, AWS, and GCP, embracing multi-cloud networking and identity synchronization alongside hybrid designs. We love DevOps, aiming to automate as much as possible to provide a practical learning environment.

The lab utilizes virtualization technologies from VMware and Hyper-V, runs VMs on Synology NAS, and explores containerization and Kubernetes clusters.

This lab is designed to demonstrate effective cloud migration and modernization strategies, from VMs to Kubernetes, including database migrations. Join us on this exciting journey; stay updated and learn with us at cloudmigration.blog.


## Authors

- [![GitHub](https://img.shields.io/badge/GitHub-attilamacskasy-181717?style=flat-square&logo=github)](https://github.com/attilamacskasy)
  [![LinkedIn](https://img.shields.io/badge/LinkedIn-attilamacskasy-0077B5?style=flat-square&logo=linkedin)](https://www.linkedin.com/in/attilamacskasy/)
  
- [![GitHub](https://img.shields.io/badge/GitHub-peterkarpati0-181717?style=flat-square&logo=github)](https://github.com/peterkarpati0)
  [![LinkedIn](https://img.shields.io/badge/LinkedIn-karpati--peter-0077B5?style=flat-square&logo=linkedin)](https://www.linkedin.com/in/karpati-peter/)

## The technologies we follow - subnet details for 172.22.22.0/24 (split into /27)

Below is how we allocate various technologies within a single /24 network. Each technology stack is assigned a /27 subnet, providing 30 usable IP addresses per segment.
This table provides a breakdown of the 172.22.22.0/24 network, divided into smaller /27 subnets.

Consider this an advanced source system for any migration and modernization tasks, whether from on-premises to the cloud or between cloud environments.

Our primary focus is on **networking and security**, with a commitment to mastering **Kubernetes’ pluggable networking architecture**, including [Project Calico](https://www.tigera.io/tigera-products/calico/).  

However, this journey is extensive—starting from mounting Windows 2003 servers on DOS 6.22 to power our retro gaming LAN party because sometimes, even cloud engineers need a break.

![Doom 2](Doom2_title.jpeg)


| Technology            | Subnet             | Netmask            | Network Address   | Usable IPs | First Usable IP  | Last Usable IP   | Broadcast Address  |
|:----------------------|:------------------|:-------------------|:------------------|-----------:|:-----------------|:-----------------|:-------------------|
| SHARED INFRA         | 172.22.22.0/27     | 255.255.255.224    | 172.22.22.0       |         30 | 172.22.22.1      | 172.22.22.30     | 172.22.22.31       |
| VMWARE VSPHERE       | 172.22.22.32/27    | 255.255.255.224    | 172.22.22.32      |         30 | 172.22.22.33     | 172.22.22.62     | 172.22.22.63       |
| MICROSOFT HYPER-V    | 172.22.22.64/27    | 255.255.255.224    | 172.22.22.64      |         30 | 172.22.22.65     | 172.22.22.94     | 172.22.22.95       |
| RED HAT             | 172.22.22.96/27    | 255.255.255.224    | 172.22.22.96      |         30 | 172.22.22.97     | 172.22.22.126    | 172.22.22.127      |
| OPEN SOURCE VIRT    | 172.22.22.128/27   | 255.255.255.224    | 172.22.22.128     |         30 | 172.22.22.129    | 172.22.22.158    | 172.22.22.159      |
| CONTAINERS          | 172.22.22.160/27   | 255.255.255.224    | 172.22.22.160     |         30 | 172.22.22.161    | 172.22.22.190    | 172.22.22.191      |
| KUBERNETES          | 172.22.22.192/27   | 255.255.255.224    | 172.22.22.192     |         30 | 172.22.22.193    | 172.22.22.222    | 172.22.22.223      |
| CLIENTS (DHCP) & NAS | 172.22.22.224/27   | 255.255.255.224    | 172.22.22.224     |         30 | 172.22.22.225    | 172.22.22.254    | 172.22.22.255      |


## Architecture Diagram v1

![CloudMigration.hu Overview](01_cloudmigrationhu_overview.jpg)



## Testing Mermaid (Peter)

We chose to use draw.io instead of Mermaid. However, with the integration of AI into our workflow, we hope that AI will eventually be able to generate diagrams as polished as the ones we create.

| Feature                   | **Mermaid**                     | **draw.io**                     |
|---------------------------|----------------------------------|----------------------------------|
| **Creation Method**       | Text-based (code)               | Graphical (drag-and-drop)       |
| **Integration in Markdown**| Inline with `mermaid` code block| Embed exported image or link     |
| **Ease of Use**           | Requires learning syntax         | Intuitive, WYSIWYG              |
| **Version Control**       | Excellent (text-based)           | Limited (binary files)          |
| **Complex Diagrams**      | Limited for very detailed designs| Handles complex diagrams easily |
| **Dependencies**          | Markdown viewer with Mermaid support| External draw.io tool required  |
| **Dynamic Editing**       | Editable within Markdown file    | Requires re-exporting           |



```mermaid
graph TD;
    subgraph Network
        DC01["<img src='data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyODQuODg2IiBoZWlnaHQ9IjM4OS42ODgiIHZpZXdCb3g9IjAgMCA3NS4zNzYgMTAzLjEwNSI+PGRlZnM+PGxpbmVhckdyYWRpZW50IGlkPSJBIiB4MT0iODMuODM5IiB5MT0iMjAwLjM5MyIgeDI9IjgzLjQ3IiB5Mj0iMTI3LjI5NSIgZ3JhZGllbnRVbml0cz0idXNlclNwYWNlT25Vc2UiPjxzdG9wIG9mZnNldD0iMCIgc3RvcC1jb2xvcj0iIzA2NzdmYyIvPjxzdG9wIG9mZnNldD0iMSIgc3RvcC1jb2xvcj0iIzhmY2FmZSIvPjwvbGluZWFyR3JhZGllbnQ+PGxpbmVhckdyYWRpZW50IGlkPSJCIiB4MT0iMTExLjI2NiIgeTE9IjIwNi4zMDQiIHgyPSIxMTEuNDgiIHkyPSIxMTguMzcyIiBncmFkaWVudFVuaXRzPSJ1c2VyU3BhY2VPblVzZSI+PHN0b3Agb2Zmc2V0PSIwIiBzdG9wLWNvbG9yPSIjMDUyMzlhIi8+PHN0b3Agb2Zmc2V0PSIxIiBzdG9wLWNvbG9yPSIjOTFiY2Y4Ii8+PC9saW5lYXJHcmFkaWVudD48bGluZWFyR3JhZGllbnQgaWQ9IkMiIHgxPSIxMDMuMDgyIiB5MT0iMTM2Ljg5IiB4Mj0iMTAzLjE5NCIgeTI9IjEwNy42MjQiIGdyYWRpZW50VW5pdHM9InVzZXJTcGFjZU9uVXNlIj48c3RvcCBvZmZzZXQ9IjAiIHN0b3AtY29sb3I9IiNhOGRlZmUiLz48c3RvcCBvZmZzZXQ9IjEiIHN0b3AtY29sb3I9IiMxMmE3ZmMiLz48L2xpbmVhckdyYWRpZW50PjxsaW5lYXJHcmFkaWVudCBpZD0iRCIgeDE9IjEyMS45NjIiIHkxPSIxNzIuMTE1IiB4Mj0iMTIxLjczNCIgeTI9IjEzNi40MTIiIGdyYWRpZW50VW5pdHM9InVzZXJTcGFjZU9uVXNlIj48c3RvcCBvZmZzZXQ9IjAiIHN0b3AtY29sb3I9IiNmZWNiNDUiLz48c3RvcCBvZmZzZXQ9IjEiIHN0b3AtY29sb3I9IiNmZTY3MDYiLz48L2xpbmVhckdyYWRpZW50PjwvZGVmcz48ZyB0cmFuc2Zvcm09InRyYW5zbGF0ZSgtNzIuNTgzIC0xMDUuNzM4KSI+PHBhdGggZD0iTTEyOS41MiAxODcuNDY4bC0zNi45NjMgMTkuNjY4VjEzNy4yMWwzNi45NjMtMTkuOTM4eiIgZmlsbD0idXJsKCNCKSIvPjxwYXRoIGQ9Ik05Mi41NTcgMjA3LjEzNkw3NC4wODMgMTk2LjkzVjEyNy4xbDE4LjQ3NCAxMC4xMSIgZmlsbD0idXJsKCNBKSIvPjxwYXRoIGQ9Ik0xMjkuNTIgMTE3LjI3Mkw5Mi41NTcgMTM3LjIxIDc0LjA4MyAxMjcuMWwzNi44NDgtMTkuNjYzeiIgZmlsbD0idXJsKCNDKSIvPjxwYXRoIGQ9Ik03OS4zNTUgMTUwLjgzdjEuMzIybDYuNjMgMy42Mzh2LTEuMzIyem0wIDYuNjczdjEuMzIybDYuNjMgMy42Mzh2LTEuMzIyeiIgZG9taW5hbnQtYmFzZWxpbmU9ImF1dG8iIGZpbGw9IiNmZmYiLz48cGF0aCBkPSJNOTIuNTU3IDEzNy4yMWwzNi45NjMtMTkuOTM4em0wIDY5LjkyNlYxMzcuMjFMNzQuMDgzIDEyNy4xbTE4LjQ3NCA4MC4wMzZMNzQuMDgzIDE5Ni45M1YxMjcuMWwzNi44NDgtMTkuNjYzIDE4LjU5IDkuODM2djcwLjE5NnoiIGZpbGw9Im5vbmUiIHN0cm9rZT0iI2ZmZiIgc3Ryb2tlLXdpZHRoPSIzIi8+PHBhdGggZD0iTTEyMS43MzIgMTI5LjI4N2wtMjYuMjEgNDYuNDg0aDUyLjQzNnoiIGRvbWluYW50LWJhc2VsaW5lPSJhdXRvIiBmaWxsPSIjZmZmIi8+PHBhdGggZD0iTTEyMS43MzQgMTM2LjQxMmwyMC4yMzIgMzUuODZoLTQwLjQ1eiIgZG9taW5hbnQtYmFzZWxpbmU9ImF1dG8iIGZpbGw9InVybCgjRCkiLz48L2c+PC9zdmc+' width='10'/><b>DC01</b><br/>172.22.22.1"]
        DC02["<img src='download.svg' width='10'/><b>DC02</b><br/>172.22.23.1"]
    end
    
```



