# Remote Server Monitor

<img width="4095" height="2052" alt="image" src="https://github.com/user-attachments/assets/643795de-4ef5-4f39-ac3a-630fc507e505" />


A simple desktop app for checking on remote Windows servers — see how busy they are, who's logged in over RDP, and kick people off when needed. No install, no dependencies, no cloud. Just run it.

---

## What it does

Point it at a server name and it shows you:

- **CPU, RAM, and Disk usage** — at a glance, with live progress bars
- **Network traffic** — upload/download speed on the active adapters
- **System info** — hostname, IP address, OS version, server date/time, and how long it's been up
- **Who's connected via RDP** — every active and disconnected remote session, with the user, session ID, client machine name, IP, how long they've been idle, and when they logged in

From there you can:

- **Disconnect one or many sessions** at once (with a confirmation prompt, so no accidents)
- **Launch an RDP session** straight to that server
- **Open the remote Services console**
- **Browse the server's C$ share** in File Explorer
- **Test whether a specific port is reachable**

---

## How to use it

1. **Start the app.** If you have the `.ps1` file, run:

   ```powershell
   powershell -ExecutionPolicy Bypass -File ".\Remote Server Monitor.ps1"
   ```

   Or, if you have the compiled `.exe`, just double-click it.

2. **Type a server name or IP** in the box on the left and click **SHOW STATUS**.

   The app will:
   - Ping the server to make sure it's reachable
   - Load the RDP session list almost immediately
   - Then fill in CPU, RAM, disk, network, and system info (takes a couple of seconds)

3. **Filter and sort the session list** on the right:

   - **Search** by username (just start typing)
   - **Filter** by state — *Active only* or *Disconnected only*
   - **Click any column header** to sort by that column. Click again to flip the direction. The little ▲ / ▼ arrow shows what's active.

4. **Disconnect someone** by clicking their row (or Ctrl-click / Shift-click to select several), then click **Disconnect Selected**. You'll get a confirmation dialog listing exactly who's about to be logged off — check it carefully, then confirm.

5. **Click Refresh List** to update the session list without re-running the full server check. Use **Refresh** in the System Information card to re-pull just the system details.

6. **Quick action buttons** become clickable once a server is loaded:

   - **Start RDP Connection** → opens `mstsc` pointed at that server
   - **Access Remote Services** → opens `services.msc` against that server
   - **Explore SMB File System** → opens `\\server\c$` in Explorer

---

## What you need

- **Windows 10, 11, or Server 2016+** on the machine you run it from
- **PowerShell 5.1** (built in to all supported Windows versions)
- **Network access** to the target server — specifically:
  - ICMP (ping) for the initial reachability check
  - WSMan / CIM (port 5985 for HTTP or 5986 for HTTPS) for the resource metrics
  - The usual RDP / SMB ports if you plan to use the quick actions
- **Admin rights on the target server** are generally needed to list sessions and disconnect users. The app uses *your* current Windows credentials — it does not prompt for a separate username/password.

If you're in a domain, the simplest setup is to run the app while logged in with a domain account that has admin rights on the target server.

---

## A few things worth knowing

- **RDP sessions only.** The session list shows people connected over Remote Desktop. Local console sessions and service accounts are hidden — they're not what you're usually looking for here.
- **Non-Windows servers are detected.** If you point it at a Linux box or network device, it notices (via the ping TTL) and shows a warning instead of throwing a bunch of confusing errors. You'll still get the hostname and IP, just not the Windows-specific metrics.
- **Nothing is saved.** No config files, no logs, no registry changes. Close the window and it's gone.
- **No auto-refresh.** Everything is user-triggered. Click **Refresh List** or **Refresh** whenever you want current numbers.
- **The Disconnect button really does log people off.** There's a confirmation prompt, but once you click *Disconnect*, that session is gone — including any unsaved work. Read the dialog before confirming, especially when multiple users are selected.
- **Closing the window closes everything.** The app cleans up after itself and exits fully. If you're running the `.ps1` directly from a PowerShell console, the console window will close too — that's on purpose, so the compiled `.exe` doesn't leave a black box sitting behind it.

---

## Troubleshooting

| What you see | What it usually means |
|---|---|
| *"Server is not reachable (ping failed)"* | The server's down, offline, or your firewall blocks ICMP. Try the IP address directly. |
| *"CIM connection failed"* | WSMan isn't reachable on the target, or your account doesn't have permission. Check firewall rules (5985/5986) and whether you're an admin on that box. |
| *"⚠ appears to be a non-Windows host"* | The app saw a low TTL and stopped trying to pull Windows metrics. If it really *is* Windows, you may have a network device in the path — the session list may still work. |
| *Session list is empty but you know people are connected* | Your account may not have permission to enumerate sessions. Try running the app as an account with admin rights on the target. |
| *Disconnect button does nothing / fails* | Same reason — `logoff /server:` needs admin rights on the target. |
| *Client column shows `—`* | The target server's WTS API didn't return client info for that session. Common for disconnected sessions. Harmless. |

---

## Tips

- **Save time on repeat checks.** Leave the app open and switch between servers by typing a new name — no need to close it.
- **Sort by Idle descending** to spot stale disconnected sessions that are safe to clean up.
- **Multi-select is your friend.** Shift-click a range or Ctrl-click individual sessions to disconnect several at once — the confirmation dialog will list every one before anything happens.
- **Hover the Disk card** to see the full per-volume breakdown. The bar itself only shows the fullest volume; the tooltip has all of them.
- **Port check is handy for RDP/WSMan/SMB troubleshooting.** Drop `3389`, `5985`, or `445` in the box to confirm connectivity on a specific service without leaving the app.
