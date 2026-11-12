# Remote Server Monitor

<img width="4095" height="2052" alt="image" src="https://github.com/user-attachments/assets/643795de-4ef5-4f39-ac3a-630fc507e505" />

> A PowerShell + WPF desktop utility for real-time monitoring and administration of remote Windows servers, with a focus on RDP session visibility, system health metrics, and quick administrative actions.

---

## 1. Overview

**Remote Server Monitor** is a single-file, GUI-driven PowerShell application that provides administrators with a lightweight, dependency-free dashboard for inspecting remote Windows hosts. It targets the operational gap between heavyweight enterprise monitoring platforms and ad-hoc `Enter-PSSession` / `mstsc` workflows.

The application is written entirely in PowerShell 5.1+ and leverages **WPF (Windows Presentation Foundation)** for its UI layer, **CIM/WMI** for remote telemetry, and **Windows Terminal Services APIs** (`wtsapi32.dll`, `quser`, `qwinsta`) for RDP session enumeration.

### Design goals

| Goal | Implementation |
|------|----------------|
| **Zero external modules** | No `Import-Module` beyond built-in assemblies |
| **Non-blocking UI** | All remote I/O runs in MTA background runspaces |
| **Graceful degradation** | Non-Windows hosts are detected via TTL and reported cleanly |
| **Single-file distribution** | Compilable via `ps2exe` with no sidecar files |
| **Defensive parsing** | quser/qwinsta output parsed by column offsets + regex fallback |

---

## 2. Version history context

The current build (`v2.3.0`) reflects an iterative refactor:

- **Overview panel removed** — simplified the left column to pure metric cards.
- **Sortable session columns** — clicking any header toggles ascending/descending sort.
- **Multi-select disconnect** — `ListBox.SelectionMode="Extended"` plus a batch-aware confirmation dialog.

---

## 3. Architecture

### 3.1 High-level data flow

```
┌─────────────────────────────────────────────────────────────┐
│  UI Thread (STA)                                            │
│  ┌──────────────┐   ┌──────────────┐   ┌────────────────┐   │
│  │ Sidebar      │   │ Metric cards │   │ Sessions table │   │
│  └──────────────┘   └──────────────┘   └────────────────┘   │
│         ▲                  ▲                   ▲            │
│         │ Dispatcher.Invoke│                   │            │
└─────────┼──────────────────┼───────────────────┼────────────┘
          │                  │                   │
          │        ┌─────────┴─────────┐         │
          │        │  SharedState      │         │
          │        │  (Synchronized    │         │
          │        │   Hashtable)      │         │
          │        └─────────┬─────────┘         │
          │                  │                   │
┌─────────┴──────────────────┴───────────────────┴────────────┐
│  Background Runspaces (MTA)                                 │
│  ┌────────────┐ ┌──────────────┐ ┌────────────┐ ┌──────────┐│
│  │ CheckServer│ │ LoadSessions │ │ Disconnect │ │ PortCheck││
│  └────────────┘ └──────────────┘ └────────────┘ └──────────┘│
│         │              │               │             │      │
│         ▼              ▼               ▼             ▼      │
│    CIM / WMI      quser/wtsapi32   logoff.exe   Test-NetConn│
└─────────────────────────────────────────────────────────────┘
```

### 3.2 Threading model

- The **UI thread** is single-threaded apartment (STA), as required by WPF.
- Each remote operation is dispatched via `Start-BackgroundTask`, which creates a dedicated `Runspace` in **MTA** mode with `ThreadOptions = 'ReuseThread'`.
- Cross-thread UI updates are marshaled through `$Window.Dispatcher.Invoke($Action, DispatcherPriority.Background)` — actions are **pre-compiled `[action]` delegates** (not inline script blocks) to avoid re-parsing cost on every invocation.
- Shared data is stored in a `[hashtable]::Synchronized(@{...})` object, which provides thread-safe access without explicit locking for single-writer/single-reader patterns.

### 3.3 Function injection

Because background runspaces start with a blank session state, all helper functions are **serialized into a single string** at startup:

```powershell
$script:FunctionSource = Get-SharedFunctionSource
```

`Get-SharedFunctionSource` walks a hardcoded list of function names, extracts `$cmd.Definition` from each, and concatenates them into a script block. Background scripts then call:

```powershell
. ([scriptblock]::Create($FunctionSource))
```

This is functionally equivalent to `Import-Module` but avoids the module-discovery overhead and works cleanly when the script is compiled to an EXE via `ps2exe` (where `$PSScriptRoot` may not point where you expect).

> **Trade-off note:** function sources are resolved once at startup. Hot-patching helper functions at runtime is not supported without re-launching.

---

## 4. UI Layer

### 4.1 Layout

The window is a two-column `Grid`:

| Column | Width | Purpose |
|--------|-------|---------|
| Left sidebar | 300 px fixed | Target input, quick actions, port check, status summary |
| Main area | `*` | Split into two equal-ish panes (400 px / 520 px minimums) |

**Left pane (main)** — scrollable stack of four metric cards:
- **CPU** — `LoadPercentage` averaged across sockets, with core/thread count.
- **RAM** — used/total/free from `Win32_OperatingSystem`.
- **DISK** — per-volume percentage with a text-mode bar (`########............`).
- **NETWORK** — RX/TX with dual progress bars.
- **System Information** — hostname/IP, OS, date/time, boot time.

**Right pane (main)** — RDP session table:
- Search box (case-insensitive substring on username).
- State filter (`All` / `Active` / `Disconnected`).
- Refresh button.
- Column header row with sort indicators (`▲` / `▼`).
- `ListBox` with `SelectionMode="Extended"` for Ctrl/Shift multi-select.
- Footer showing selection summary + Disconnect button.

### 4.2 Styling

All styling is declared in `<Window.Resources>` using named `Style` keys:

| Key | Purpose |
|-----|---------|
| `Card` | White border with 10 px radius, 1 px `#E2E6EC` border |
| `CardTitle` | 13 px bold, `#1F2933` |
| `SubtleLabel` | 11 px semibold, muted grey |
| `MonoValue` | `Consolas` 12 px, wraps |
| `PrimaryButton` | Blue `#2563EB` background, white text |
| `GhostButton` | Dark `#2A3444` background, light text |

Color choices follow a soft "enterprise" palette — teal (`#14B8A6`) for CPU, blue (`#3B82F6`) for RAM, amber (`#F59E0B`) for disk, purple (`#A855F7`) for network.

### 4.3 XAML loading

The entire window definition is an inline here-string parsed by `[Windows.Markup.XamlReader]::Load`. Named elements are resolved via `$window.FindName(...)` at startup and stored in `$script:`-scoped variables for fast access from event handlers.

---

## 5. Remote Data Collection

### 5.1 Server connectivity probe

`Test-Connection` confirms the host is reachable, then `Get-PingTtl` parses the TTL from `ping -4 -n 1 -w 1000` output:

| TTL range | Inferred OS |
|-----------|-------------|
| `128` | Windows (initial TTL 128) |
| `64` | Linux/Unix (initial TTL 64) |
| `255` | Network device |

A TTL `< 100` triggers the `NonWindowsHint` path: resource queries are skipped, but sessions are still attempted.

### 5.2 CIM session

`New-CimSession -ComputerName $Server` establishes a WSMan/DCOM session. All subsequent metric queries reuse the same session, then `Remove-CimSession` is called at the end.

### 5.3 CPU

```powershell
Get-CimInstance -CimSession $cim -ClassName Win32_Processor
```

- `LoadPercentage` is averaged over all sockets → `pbCpu.Value`.
- `NumberOfCores` and `NumberOfLogicalProcessors` are summed for the tooltip.

### 5.4 RAM

```powershell
Get-CimInstance -CimSession $cim -ClassName Win32_OperatingSystem
```

- `TotalVisibleMemorySize` and `FreePhysicalMemory` are reported in **KB**, converted via `* 1KB`.
- Usage percentage is `used / total * 100`.

### 5.5 Disk

```powershell
Get-CimInstance -CimSession $cim -ClassName Win32_LogicalDisk -Filter "DriveType=3"
```

Only **fixed disks** (`DriveType=3`) are enumerated. For each volume:
- A 20-character bar is generated: `("#" * [int]($pct / 5)).PadRight(20, '.')`.
- Output is shown as a condensed one-line summary (`C: 42%`) with a **full per-disk breakdown in the tooltip**.

The progress bar tracks the **highest-used** volume, not the aggregate.

### 5.6 Network throughput

`Get-NetworkThroughput` uses a **two-sample delta technique** on `Win32_PerfRawData_Tcpip_NetworkInterface`:

1. Read raw counters (`BytesReceivedPersec`, `BytesSentPersec`, `Timestamp_PerfTime`, `Frequency_PerfTime`) at T₀.
2. `Start-Sleep -Seconds 1`.
3. Read counters again at T₁.
4. Compute `Δbytes / Δt * 8` to convert bytes/sec → bits/sec.

Adapters are filtered with a regex to exclude virtual/noise interfaces:

```regex
isatap|Loopback|Teredo|Pseudo|Tunnel|vEthernet|Virtual|Bluetooth|WAN Miniport
```

Link speed is fetched per-adapter via `Win32_NetworkAdapter` for percentage normalization; if unavailable, a 10 Mbps fallback is used to keep the progress bars meaningful.

---

## 6. RDP Session Enumeration

This is the most intricate subsystem in the application.

### 6.1 Primary source: `quser`

```powershell
quser /server:$Server
```

Output is parsed by `Parse-QuserOutput` using **column-offset extraction**:

1. Locate the header line by matching `(?i)USERNAME`.
2. Extract column start indices: `Index of "USERNAME"`, `"SESSIONNAME"`, `"ID"`, `"STATE"`, `"IDLE"`, `"LOGON"`.
3. For each data line, slice by offsets to get `user`, `session`, `id`, `state`, `idle+logon-rest`.

A **regex fallback** kicks in if the offsets are invalid (e.g., localized output where the header wording changes):

```powershell
$parts = ($line -replace '\s+', ' ').Trim() -split ' '
```

The idle/logon split uses:

```regex
^(.*?)\s+((?:\d{1,4}[\/\-\.]\d{1,2}[\/\-\.]\d{1,4})\s+.*)$
```

— i.e., everything before the first date-shaped token is idle; the rest is logon time.

### 6.2 Fallback source: `qwinsta`

If `quser` returns no usable rows, `qwinsta /server:$Server` is tried. Parsing is simpler (`\s{2,}` split) but idle time and logon time are not available.

### 6.3 Session filtering

The app is **RDP-focused**. Sessions are filtered by station name and state:

- `^rdp-tcp` → keep (RDP session).
- `^console$` → **discard** (local console, out of scope).
- `Disc*` with empty station → keep (disconnected RDP session whose station name was elided).
- `Listen` state → discard (listener channel, not a real user).
- Noisy service accounts (`SYSTEM`, `DWM-1`, `UMFD-0`, etc.) → discard.

### 6.4 Idle time normalization

`ConvertTo-IdleMinutes` parses quser's raw idle string into a numeric minute value:

| Raw value | Parsed minutes |
|-----------|---------------|
| `.` | `0` (actively typing) |
| `none` / `n/a` / `-` / `—` | `$null` (unknown) |
| `12` | `12` |
| `1:23` | `1h 23m` = 83 |
| `1+2:34` | `1d 2h 34m` = 1594 |

Matching regex:

```regex
^(?:(\d+)\+)?(\d{1,3})(?::(\d{1,2}))?$
```

Formatting is the inverse: `Format-IdleDuration` collapses to `Xd Yh Zm`, omitting leading zero components.

> **Why this matters:** native sorting on the raw string would put `1:30` after `9` lexically. By normalizing to minutes, sorting in `Render-Sessions` can use `IdleMinutes` numerically. Sessions with unknown idle always sink to the end regardless of sort direction.

### 6.5 Client name and IP via WTS API

`quser` and `qwinsta` do **not** expose the RDP client's machine name or IP address. To fill that gap, the script P/Invokes `wtsapi32.dll`:

```csharp
WTSOpenServerA / WTSCloseServer
WTSQuerySessionInformationA(hServer, sessionId, WTSClientName=10, ...)
WTSQuerySessionInformationA(hServer, sessionId, WTSClientAddress=14, ...)
```

The address is a `WTS_CLIENT_ADDRESS` structure:

```
DWORD AddressFamily;   // 0x00000002 = AF_INET
BYTE  Address[20];     // IP in offset 4..7 (or 0..3 fallback)
```

`Initialize-WtsHelper` compiles the C# via `Add-Type -TypeDefinition` **only once** (guarded by `'RemoteMonitor.WtsHelper' -as [type]`). If `Add-Type` fails (locked-down environment), the app continues without client info — the columns show `—`.

---

## 7. Interactive Features

### 7.1 Sorting

`$script:SortColumn` and `$script:SortAscending` hold the active sort state. Clicking a header calls `Invoke-SortByColumn`, which:

1. Flips direction if the same column, else resets to ascending.
2. Calls `Update-SortIndicators` to append `▲`/`▼` to the header text and bold-blue it.
3. Re-renders using the current filter and search.

Special-cased: the `Idle` column sorts on `IdleMinutes` with unknown values pushed to the bottom:

```powershell
$sorted = $filtered | Sort-Object -Property `
    @{ Expression = { $null -eq $_.IdleMinutes } }, `
    @{ Expression = { if ($null -eq $_.IdleMinutes) { 0 } else { $dir * [double]$_.IdleMinutes } } }
```

### 7.2 Filtering

Two independent filters compose additively:

- **State filter** (`cmbStateFilter`) — `All` / `Active` / `Disconnected` (matched via `StateRaw`).
- **Search** (`txtSearchUser`) — case-insensitive substring on `User`.

Both `SelectionChanged` and `TextChanged` handlers re-run `Render-Sessions` with the current sort.

### 7.3 Multi-select

`ListBox.SelectionMode="Extended"` enables Ctrl+Click and Shift+Click. `SelectionChanged` handles three cases:

- **0 items** → button disabled, footer cleared.
- **1 item** → detail view (user, session, state, client).
- **N items** → comma-joined preview (first 5, then `...`).

### 7.4 Disconnect flow

```
btnDisconnect.Click
  → collect SelectedItems → $sessions
  → Show-DisconnectConfirmation (modal WPF dialog)
      → build custom XAML for single vs. multi
      → ShowDialog() → $script:confirmResult
  → if confirmed: Disconnect-Session (background)
      → for each target: logoff <id> /server:<srv>
      → Dispatcher updates status/footer
      → reload session list
```

The confirmation dialog is itself a **dynamically constructed WPF window** — not a `MessageBox` — so it can render the full per-user table with styled colors. Session ID validation happens in `Disconnect-Session` before the background task is even dispatched.

### 7.5 Quick actions

Three one-click launch buttons become enabled after a successful check:

| Button | Command |
|--------|---------|
| Start RDP Connection | `mstsc.exe /v:$server` |
| Access Remote Services | `mmc.exe services.msc /computer=$server` |
| Explore SMB File System | `explorer.exe \\$server\c$` |

Each is wrapped in `try/catch` and reports failures in the status text — no silent failures.

### 7.6 Port check

`Test-NetConnection -ComputerName -Port` runs in a background runspace. Result is styled green (`#4ADE80`) on success, red (`#F87171`) on failure. The port box defaults to `443` and accepts `1–65535` (validated via `[int]::TryParse`).

---

## 8. Error Handling & Resilience

The application follows a **layered catch** strategy:

| Layer | Behavior |
|-------|----------|
| **Connectivity** | Ping failure → abort, show error in status |
| **Non-Windows** | TTL < 100 → skip CIM, populate host/IP only, show ⚠ banner |
| **CIM** | `New-CimSession` failure → abort metrics, retain sessions |
| **Per-metric** | Individual card catches show inline error in that card's detail field |
| **Per-session** | quser failure → fallback to qwinsta → empty list |
| **WTS API** | `Add-Type` failure → graceful omission of client columns |
| **Disconnect** | Per-target try/catch; aggregates `$ok` / `$fail` / `$failMsgs` |

Every background script ends with a `finally` block that re-enables the corresponding button — **no UI element can get stuck in a disabled state** even after an unhandled exception.

---

## 9. Build & Distribution

### 9.1 Requirements

- **PowerShell 5.1** or later (Windows PowerShell — this is not a PowerShell 7+ / `pwsh` app; WPF via `PresentationFramework` is Windows-only).
- **Windows 10/11** (or Server 2016+) on the client machine.
- **WSMan / CIM** reachable on the target host (typically port 5985 or 5986 for HTTPS, or DCOM 135 for legacy).
- **Administrator privileges** on the target are generally required to enumerate RDP sessions and call `logoff`.

### 9.2 Running from source

```powershell
.\"Remote Server Monitor.ps1"
```

If the execution policy blocks it:

```powershell
powershell -ExecutionPolicy Bypass -File ".\Remote Server Monitor.ps1"
```

### 9.3 Compiling to a standalone EXE

The file is **`ps2exe`-ready**. The final two lines:

```powershell
$window.ShowDialog() | Out-Null
try { [System.Diagnostics.Process]::GetCurrentProcess().Kill() } catch { }
```

…are an explicit cleanup pattern that kills the host process after the WPF window closes. This prevents the console window from lingering when `ps2exe` wraps the script in a WinExe.

> ⚠️ **Warning:** this pattern will also terminate the parent PowerShell host if you run the `.ps1` directly from an interactive console. If you plan to `dot-source` or run interactively, comment out the final `Kill()` block.

### 9.4 Antivirus / EDR considerations

- The script calls `logoff.exe` via `Start-Process` → this is a documented administrative tool but is sometimes flagged when invoked remotely.
- The embedded C# in `Initialize-WtsHelper` is compiled with `Add-Type`, which some heuristics treat as suspicious.
- Both behaviors are benign but should be allowlisted in managed environments.

---

## 10. Security Posture

| Concern | Mitigation |
|---------|-----------|
| **Credential handling** | None — relies on the caller's existing Kerberos/NTLM identity. No passwords are read or stored. |
| **Transport** | CIM over WSMan (Kerberos by default); `logoff` uses RPC. |
| **Input validation** | Server name passed through `Resolve-IfIP`; port validated with `[int]::TryParse`; session IDs cast to `[int]`. |
| **XAML injection** | All interpolated strings in the confirmation dialog are passed through `[System.Security.SecurityElement]::Escape`. |
| **Destructive action** | `logoff` is gated behind a **modal confirmation dialog** requiring explicit click. |
| **No persistence** | No registry writes, no config files, no logs on disk. |

The app **does not** support specifying alternate credentials. If you need cross-domain or explicit-credential scenarios, wrap the launch in `runas /netonly` or a `New-PSSession`-based flow.

---

## 11. Known Limitations

1. **Windows-only.** WPF + CIM + Terminal Services APIs.
2. **PowerShell 5.1 only.** Not tested against PowerShell 7's `System.Management.Automation` for WPF (which has subtle interop differences).
3. **RDP sessions only.** Console and RemoteApp sessions are filtered out by design.
4. **No persistent sorting.** Sort state resets on refresh — by design, so refreshes always present a predictable ordering.
5. **No auto-refresh.** All data collection is user-triggered. The card UI is designed for on-demand polling, not continuous streaming.
6. **Network throughput is instantaneous.** Two 1-second samples; a burst of traffic in that window will be reported, but sustained averages are not tracked.
7. **The `Idle` column relies on `quser`.** If the fallback `qwinsta` path is taken, idle always shows `—`.
8. **`Remove-CimSession` is best-effort.** If the remote host goes offline mid-query, the session object may remain until the runspace is garbage collected.

---

## 12. Extension Points

The codebase is intentionally structured to make these enhancements straightforward:

| Extension | Where to start |
|-----------|---------------|
| Add a metric card (e.g., GPU, paging file) | `Reset-UI`, then a new `<Border Style="{StaticResource Card}">` in XAML, then a `Get-CimInstance` block in `CheckServerScript` |
| Add a sortable column | Add `<ColumnDefinition>` + `<Button>` in XAML header grid, add binding column in the `DataTemplate`, extend `Update-SortIndicators` and `Invoke-SortByColumn` |
| Add a quick action (e.g., Event Viewer) | Add button to the `QUICK ACTIONS` StackPanel, wire a `Start-Process` handler |
| Add a background task | Follow the `$script:PortCheckScript` pattern: `param(...)`, `Update-UI` helper, `try/catch/finally` |
| Change color theme | All colors live in the XAML here-string — search for `#2563EB` (primary), `#1B2430` (sidebar), etc. |
| Add credential support | Wrap `New-CimSession` with `-Credential`; add a `PSCredential` prompt before `Check-Server` |

Because all shared helpers are listed in `Get-SharedFunctionSource`, adding a new helper function requires **two edits**: define it, and add its name to the `$names` array — otherwise background runspaces will fail with `CommandNotFoundException`.

---

## 13. License / Attribution

No license header is embedded in the source. If publishing to GitHub, add an appropriate `LICENSE` file (MIT / Apache-2.0 recommended for tooling like this) and note any restrictions on `wtsapi32.dll` usage (which is documented Windows SDK API, freely usable).

---

## 14. Quick reference — file map

```
Remote Server Monitor.ps1
├── Assembly loads (PresentationFramework, PresentationCore, WindowsBase)
├── Inline XAML (Window definition)
├── Named element resolution ($window.FindName ...)
├── Shared state ($script:SharedState synchronized hashtable)
├── Sort state ($script:SortColumn, $script:SortAscending)
├── Formatting helpers (Format-Bytes, Format-BitsPerSec, ...)
├── Idle-time helpers (ConvertTo-IdleMinutes, Format-IdleDuration)
├── Resolve-IfIP
├── Get-PingTtl
├── Get-NetworkThroughput
├── Parse-QuserOutput
├── WTS interop (Initialize-WtsHelper, Get-RdpClientInfo)
├── Get-RemoteSessions
├── Get-SharedFunctionSource  ← single source of truth for injected functions
├── Start-BackgroundTask
├── Reset-UI
├── Sort helpers (Update-SortIndicators, Invoke-SortByColumn)
├── Render-Sessions
├── Pre-built UI delegates ($RefreshSessionsAction, $ReloadSessionsAction)
├── Background scripts:
│   ├── CheckServerScript    (sessions + all metrics)
│   ├── LoadSessionsScript   (sessions only)
│   ├── DisconnectScript     (logoff × N)
│   └── PortCheckScript      (Test-NetConnection)
├── Orchestration: Check-Server, Load-RemoteSessions
├── Show-DisconnectConfirmation (dynamic modal window)
├── Disconnect-Session
├── Event handlers (btnCheck, btnClear, headers, selection, ...)
├── Window closed handler (process kill)
└── ShowDialog + final process kill (ps2exe cleanup)
```
