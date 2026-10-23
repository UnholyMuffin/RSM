# Remote Server Monitor

<img width="1600" height="843" alt="WhatsApp Image 2026-10-23 at 09 19 28" src="https://github.com/user-attachments/assets/bfcbfbe5-23ef-4325-b802-e2b20e21b7dc" />


A WPF desktop GUI written in PowerShell for monitoring a remote Windows server's health and managing its RDP sessions from a single window.

![Version](https://img.shields.io/badge/version-2.1.3-blue)
![Platform](https://img.shields.io/badge/platform-Windows-lightgrey)
![PowerShell](https://img.shields.io/badge/PowerShell-5.1-blue)
![License](https://img.shields.io/badge/license-MIT-green)

---

## Overview

Remote Server Monitor is a single-file PowerShell script (`.ps1`) that launches a WPF dashboard. It queries a remote Windows host over ping, CIM (WinRM), and the built-in `quser` / `qwinsta` console tools, then presents the results in a clean, card-based UI.

It is designed for system administrators who want a fast, at-a-glance view of a server's health — and the ability to disconnect stuck RDP sessions — without opening Task Manager, Event Viewer, or an RDP window.

The script can be run directly or packaged into a standalone `.exe` with [ps2exe](https://github.com/MScholtes/PS2EXE).

---

## Features

| Feature | Description |
|---|---|
| **Availability check** | Ping test before any queries |
| **TTL-based OS heuristic** | If observed TTL < 100, warns that the host is likely Linux/non-Windows and skips CIM queries |
| **CPU metrics** | Load %, processor name, physical cores / logical threads |
| **RAM metrics** | Used / total / free, percentage |
| **Disk metrics** | Per fixed volume: usage %, used / total / free (full detail in hover tooltip) |
| **Network throughput** | RX/TX per active adapter, 1-second sample, aggregate totals |
| **OS information** | Caption, version, build, architecture, service pack, install date |
| **Server date/time** | Local time, time zone, offset vs. admin's PC |
| **Boot time / uptime** | Last boot timestamp and uptime in days/hours/minutes/seconds |
| **RDP sessions** | Active and disconnected sessions: user, session ID, state, station, idle, logon time |
| **State filter** | All / Active only / Disconnected only |
| **Copy list** | Copy the formatted session table to the clipboard |
| **Disconnect session** | Force logoff a selected user with a confirmation dialog |
| **IP → hostname resolution** | If an IP is entered, resolves it to a short hostname |

---

## Requirements

### Admin workstation
- Windows 10 / 11 or Windows Server 2016+
- Windows PowerShell 5.1 (built-in)
- `quser.exe`, `qwinsta.exe`, `ping.exe`, `logoff.exe` in `PATH` (standard Windows)

### Target server
- Windows Server 2012 R2 or newer
- WinRM enabled (for CIM queries)
- RPC accessible (for `quser` / `qwinsta` / `logoff`)
- ICMP reachable (for the ping test)

### Permissions
- Local administrator on the target server — required for `quser`, `qwinsta`, `logoff`, and most `Win32_*` CIM classes
- On the target server, `Full Control` on the RDP listener is required to disconnect other users' sessions

---

## Usage

### Run directly from PowerShell

```powershell
powershell -ExecutionPolicy Bypass -File "Remote Server Monitor.ps1"
