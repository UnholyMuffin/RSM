# Remote Server Monitor

<img width="4095" height="2052" alt="image" src="https://github.com/user-attachments/assets/643795de-4ef5-4f39-ac3a-630fc507e505" />



---

# Remote Server Monitor

A PowerShell WPF tool for monitoring Windows servers over the network — CPU, RAM, disk, network throughput, RDP sessions, and client info — in one clean desktop GUI. No agents, no installation on the target.

![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue?logo=powershell)
![Platform](https://img.shields.io/badge/Platform-Windows-0078D4?logo=windows)

---

## What it does

Point it at a hostname or IP, hit **CHECK STATUS**, and it shows:

- **CPU / RAM / Disk** — live usage with progress bars
- **Network** — RX/TX throughput sampled over 1 second
- **System info** — hostname + IPs, OS version, remote date/time, boot time, uptime
- **RDP sessions** — active and disconnected users with session ID, state, client hostname, idle time, logon time
- **Quick actions** — launch RDP, open remote `services.msc`, browse `\\server\c$`
- **Port check** — test whether a TCP port is reachable

All queries run in background runspaces, so the UI never freezes.

---

## Screenshot

> _Add a screenshot of the GUI here._

---

## Requirements

- **Windows** (client side)
- **PowerShell 5.1** or newer — no modules to install
- Network access to the target on **ICMP**, **RPC/WMI** (135 + dynamic range), and **Terminal Services RPC**
- An account with permission to query the target (WMI read + Terminal Services query)

No agent or service on the target server is required.

---

## Usage

**From PowerShell:**
```powershell
.\RemoteServerMonitor.ps1
