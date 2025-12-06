
## Cloudbase-Init Windows Domain Join – Project Overview

### The problem

On Proxmox (and most other KVM platforms) there are **no free, official Windows cloud images**:

- You cannot just download a “Windows image” the way you would with Ubuntu or CentOS.
- To use **cloud-init** features on Windows, you need **Cloudbase-Init**, which expects a specially prepared guest.
- Building that image by hand (install, configure, domain join logic, sysprep, capture) is **tedious and easy to get wrong**.

As a result, many people either skip automation for Windows entirely or fall back to fragile one-off scripts on each VM.

### The purpose of this project

This project explores how to **automate Windows image preparation and domain join in a Proxmox + Cloudbase-Init world**, using AI-assisted PowerShell and open documentation.

Goals:

- Create a **repeatable recipe** for a Windows VM that works well with **Cloudbase-Init** and Proxmox cloud-init.
- Make it easy to **auto-join Windows VMs to a domain** during first boot, using cloud-init style metadata instead of manual clicks.
- Show how on-premises Proxmox can get **“cloud-like” Windows automation**, similar to what VMware Horizon or Citrix environments have, but with **free and open components**.

This is not just a one-off script – it’s a **building block** toward a full, self-service VDI / lab environment on Proxmox.

### Why this is cool and important

- **Cloud-style automation for Windows**: Bring the same “cloud-init” experience you know from Linux to Windows VMs on Proxmox.
- **Bridges a real gap**: The lack of official Windows cloud images means everyone has to reinvent this; this project documents the path.
- **On-prem, open, and affordable**: Combine Proxmox + Cloudbase-Init + PowerShell to get capabilities similar to big commercial stacks, without the licensing overhead.
- **AI-assisted infrastructure**: The scripts and docs are intentionally written in a clear, explain-what-we-do style so they are easy to extend, regenerate, or refactor with tools like GitHub Copilot / AI assistants.

If you care about **repeatable Windows deployments**, lab automation, VDI, or “infrastructure as code” for on-prem environments, this project is meant to be useful out-of-the-box and also a good template to learn from.

### What to expect from this folder

In this `cloudbase-init-windows-domain-join` folder you’ll typically find:

- PowerShell scripts and example configs that:
	- Assume **Cloudbase-Init** is installed on the Windows template.
	- Show how to wire **cloud-init / metadata** (from Proxmox) into **Windows domain join** parameters.
	- Are designed to work cleanly with **Sysprep** and template cloning.
- A focus on **readability and explanation** over clever one-liners – the goal is that you can adapt this to your own AD, OU structure, and security rules.

The bigger picture across the repo is a step-by-step journey: from raw Windows install ➜ optimized master image ➜ sysprep-ready Proxmox template ➜ automatically configured, domain-joined Windows VMs.

### Background / references

For context on how Proxmox and Cloudbase-Init fit together, see the official Proxmox docs:

- Cloud-Init on Windows (Proxmox wiki):  
	https://pve.proxmox.com/wiki/Cloud-Init_Support#_cloud_init_on_windows

Key points from that page:

- **Cloudbase-Init** is the Windows implementation of cloud-init.
- Not every Linux cloud-init feature is available; some behaviors differ.
- For Windows guests using Cloudbase-Init on Proxmox you typically need:
	- `ostype` set to a Windows type.
	- `citype` set to `configdrive2` (default for Windows ostype in Proxmox).
- There are **no free official Windows cloud images**, so you must build your own base image – which is exactly the gap this project helps to close.

Use this directory as a reference and a starting point for your own **cloudbase-init aware, domain-join ready** Windows templates.




