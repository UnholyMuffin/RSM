# Remote Server Monitor

<img width="4096" height="2052" alt="image" src="https://github.com/user-attachments/assets/fd2e10e2-e58e-447b-8ad1-6a6608f6dedb" />

Here is a complete, professional `README.md` for version 2.5.0, ready to be pasted directly into your GitHub repository.

***

# 🖥️ Remote Server Monitor (RSM) - v2.5.0

A lightweight, modern WPF dashboard built entirely in PowerShell for monitoring remote Windows servers, managing RDP sessions, and communicating with active users.

No installation required. No external dependencies. Just run the script.

![Version](https://img.shields.io/badge/version-2.5.0-blue)
![Platform](https://img.shields.io/badge/platform-Windows%20Server%202008R2%2B-lightgrey)
![Language](https://img.shields.io/badge/language-PowerShell-5391FE)

---

## ✨ What's New in v2.5.0?

The headline feature of this release is the **Send Message** functionality. You can now easily broadcast alerts, maintenance warnings, or notifications directly to users' screens over RDP.

### 💬 Native Messaging via WTS API
* **Send Pop-up Messages:** Select one or multiple users from the session list and send them a native Windows MessageBox.
* **Pre-Reboot Notifications:** Perfect for warning users about upcoming server reboots or maintenance windows.
* **Customizable Dialog:** Choose the message title, write a multi-line body, and set an auto-close timeout (default 120 seconds).
* **Task Manager Engine:** Uses the modern `WTSSendMessageW` API (the same protocol Task Manager uses), bypassing the deprecated and often disabled `msg.exe` service.

---

## 🚀 Core Features

* **Real-time Resource Monitoring:** View CPU, RAM, Disk usage, and Network throughput (RX/TX).
* **RDP Session Management:** View active and disconnected RDP sessions, complete with Client Name, IP Address, Idle Time, and Logon Time.
* **Session Disconnection:** Safely (or forcibly) log off single or multiple selected sessions.
* **Advanced Table Sorting & Filtering:** Search for users, filter by Active/Disconnected state, and sort columns numerically or alphabetically.
* **Quick Actions:** One-click shortcuts to launch RDP (`mstsc`), open Remote Services (`services.msc`), explore SMB shares (`\\server\c$`), or open a WinRM PowerShell session.
* **Port Tester:** Built-in quick TCP port checker (defaults to port 443).
* **Smart Fallbacks:** Automatically detects if the target is a non-Windows host (via Ping TTL) and gracefully skips incompatible WMI/CIM queries.

---

## 🛠️ Requirements & Compatibility

### 💻 Client (Where you run the script)
* **OS:** Windows 10 / Windows 11 / Windows Server (desktop experience).
* **PowerShell:** PowerShell 5.1 (built into Windows) or PowerShell 7+.
* **Permissions:** Requires Domain Admin rights (or local admin on the target servers) to query CIM/WMI data and manage RDP sessions.

### 🖥️ Target Servers (What you monitor)
* **OS:** Windows Server 2008 R2 through Windows Server 2022.
* **WinRM / RPC:** Must be enabled and accessible through the firewall for remote CIM/WMI queries. 
* **Messaging:** The target server must have the RDP service running and allow RPC traffic.

> **⚠️ Note on Windows Server 2012 R2 Messaging:** 
> While `WTSSendMessageW` is natively supported, some heavily locked-down 2012 R2 environments may restrict the RPC calls. Ensure your admin account has the **"Message"** privilege (`tsconfig.msc` -> RDP-Tcp Properties -> Permissions) on the target server.

---

## 📦 Installation & Usage

Since RSM is a single script, deployment is incredibly simple:

1. Download the `RSM 2.5.0.ps1` file to your local machine.
2. Right-click the file and select **Run with PowerShell** (or execute it from an elevated PowerShell console).
3. *(Optional)* Compile it to an `.exe` using `ps2exe` for a standalone, double-clickable application:
   ```powershell
   Invoke-PS2EXE -InputFile ".\RSM 2.5.0.ps1" -OutputFile ".\RSM.exe" -NoConsole
   ```

### How to use:
1. Enter the target **Hostname** or IP address in the left sidebar and click **SHOW STATUS**.
2. The dashboard will populate with system metrics and query the active RDP sessions.
3. **To send a message:** Select one or multiple users in the list, click **Send Message**, compose your text, and hit send. 

---

## 🧠 Technical Details (How it works)

* **UI Framework:** Built with WPF (Windows Presentation Foundation) via XAML loaded dynamically into PowerShell.
* **Concurrency:** Long-running queries (like the 1-second network sampling and session parsing) are offloaded to background runspaces. The UI **never freezes**.
* **Session Parsing:** Utilizes a robust parser for `quser` output, capable of handling localized Windows formats.
* **RDP Client Info:** Extracts client IP addresses and hostnames by directly interfacing with `wtsapi32.dll` (WTSClientAddress and WTSClientName).
* **Messaging Engine:** Utilizes `WTSSendMessageW` (Unicode) via P/Invoke, ensuring messages are delivered even when the legacy Messenger service is disabled.

---

## 🛡️ License

This project is open-source. Please feel free to fork, modify, and distribute as needed. 

*Disclaimer: This tool provides highly privileged access to remote servers. Please test thoroughly in a development environment before using it in a production environment.*
