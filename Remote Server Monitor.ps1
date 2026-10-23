# Remote Server Monitor - WPF GUI
# Version 2.1.3 - Layout: sidebar | metrics+info | sessions
#   * Sidebar (server input + status) unchanged structurally
#   * Left column: vertical KPI stack (CPU, RAM, DISK, NETWORK) + System Information
#   * Right column: Remote Sessions (full height)
#   * Sessions come from quser (primary) or qwinsta (fallback) only
#   * TTL heuristic — if ping TTL < 100, warn that the host is likely
#     Linux/non-Windows (Windows initial TTL is 128; Linux is 64)
#   * Status / footer text brightened for better contrast on the dark sidebar
#   * FIX (ps2exe): window Closed handler force-terminates the host process so
#     it does not linger in Task Manager after the app is closed.
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase

# ---------------- Main window XAML ----------------
[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Remote Server Monitor v2.1.3" Height="900" Width="1420"
        WindowStartupLocation="CenterScreen"
        WindowState="Maximized"
        Background="#EEF1F5">

    <Window.Resources>
        <Style x:Key="Card" TargetType="Border">
            <Setter Property="Background" Value="White"/>
            <Setter Property="BorderBrush" Value="#E2E6EC"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="CornerRadius" Value="10"/>
            <Setter Property="Padding" Value="16"/>
        </Style>

        <Style x:Key="CardTitle" TargetType="TextBlock">
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="FontWeight" Value="Bold"/>
            <Setter Property="Foreground" Value="#1F2933"/>
        </Style>

        <Style x:Key="SubtleLabel" TargetType="TextBlock">
            <Setter Property="FontSize" Value="11"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="Foreground" Value="#8A94A6"/>
        </Style>

        <Style x:Key="MonoValue" TargetType="TextBlock">
            <Setter Property="FontFamily" Value="Consolas"/>
            <Setter Property="FontSize" Value="12"/>
            <Setter Property="Foreground" Value="#2D3748"/>
            <Setter Property="TextWrapping" Value="Wrap"/>
        </Style>

        <Style x:Key="PrimaryButton" TargetType="Button">
            <Setter Property="Background" Value="#2563EB"/>
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="FontWeight" Value="Bold"/>
            <Setter Property="Cursor" Value="Hand"/>
        </Style>

        <Style x:Key="GhostButton" TargetType="Button">
            <Setter Property="Background" Value="#2A3444"/>
            <Setter Property="Foreground" Value="#DCE3EC"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Cursor" Value="Hand"/>
        </Style>
    </Window.Resources>

    <Grid>
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="300"/>
            <ColumnDefinition Width="*"/>
        </Grid.ColumnDefinitions>

        <!-- ==================== SIDEBAR ==================== -->
        <Border Grid.Column="0" Background="#1B2430">
            <Grid Margin="20">
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="*"/>
                    <RowDefinition Height="Auto"/>
                </Grid.RowDefinitions>

                <StackPanel Grid.Row="0" Margin="0,0,0,22">
                    <TextBlock Text="SERVER MONITOR" Foreground="#5B9BFF"
                               FontSize="11" FontWeight="Bold"/>
                    <TextBlock Text="Remote Console" Foreground="White"
                               FontSize="20" FontWeight="Bold" Margin="0,4,0,0"/>
                    <TextBlock Text="v2.1.3" Foreground="#5B6B7F"
                               FontSize="10" Margin="0,2,0,0"/>
                </StackPanel>

                <StackPanel Grid.Row="1">
                    <TextBlock Text="TARGET SERVER" Foreground="#7A8AA0"
                               FontSize="10" FontWeight="Bold" Margin="0,0,0,6"/>
                    <Border Background="#121A24" CornerRadius="6" Padding="2">
                        <TextBox Name="txtServer" Height="32" FontSize="13"
                                 Background="#121A24" Foreground="#E6ECF4"
                                 BorderThickness="0" Padding="10,4"
                                 VerticalContentAlignment="Center"
                                 CaretBrush="#5B9BFF"/>
                    </Border>

                    <Button Name="btnCheck" Content="CHECK SERVER"
                            Height="36" Margin="0,10,0,0"
                            Style="{StaticResource PrimaryButton}"/>

                    <Button Name="btnClear" Content="Clear"
                            Height="30" Margin="0,8,0,0"
                            Style="{StaticResource GhostButton}"/>
                </StackPanel>

                <StackPanel Grid.Row="2" Margin="0,26,0,0">
                    <TextBlock Text="STATUS" Foreground="#7A8AA0"
                               FontSize="10" FontWeight="Bold" Margin="0,0,0,8"/>
                    <Border Background="#121A24" CornerRadius="6" Padding="12">
                        <StackPanel>
                            <TextBlock Name="txtStatus"
                                       Text="Enter a server name and click Check Server."
                                       Foreground="#E6ECF4" FontSize="12"
                                       FontWeight="SemiBold"
                                       TextWrapping="Wrap" LineHeight="17"/>
                            <Border Height="1" Background="#2A3444"
                                    Margin="0,10,0,10"/>
                            <TextBlock Name="txtFooter" Text="Ready"
                                       Foreground="#A8B6C8" FontSize="10.5"
                                       TextWrapping="Wrap" LineHeight="15"/>
                        </StackPanel>
                    </Border>
                </StackPanel>
            </Grid>
        </Border>

        <!-- ==================== MAIN ==================== -->
        <Grid Grid.Column="1" Margin="20">
            <Grid.RowDefinitions>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="*"/>
            </Grid.RowDefinitions>

            <Grid Grid.Row="0" Margin="0,0,0,16">
                <StackPanel>
                    <TextBlock Text="Overview" Foreground="#1F2933"
                               FontSize="22" FontWeight="Bold"/>
                    <TextBlock Text="Real-time server health and RDP session control"
                               Foreground="#7A8AA0" FontSize="12" Margin="0,2,0,0"/>
                </StackPanel>
            </Grid>

            <Grid Grid.Row="1">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="1*" MinWidth="400"/>
                    <ColumnDefinition Width="16"/>
                    <ColumnDefinition Width="1.15*" MinWidth="520"/>
                </Grid.ColumnDefinitions>

                <!-- LEFT: metrics + info -->
                <ScrollViewer Grid.Column="0"
                              VerticalScrollBarVisibility="Auto"
                              HorizontalScrollBarVisibility="Disabled">
                    <StackPanel>

                        <!-- CPU card -->
                        <Border Style="{StaticResource Card}" Margin="0,0,0,12">
                            <StackPanel>
                                <Grid>
                                    <TextBlock Text="CPU" Style="{StaticResource CardTitle}"
                                               Foreground="#0F766E"/>
                                    <TextBlock Name="txtCpuPct" Text="—"
                                               HorizontalAlignment="Right"
                                               Foreground="#0F766E" FontSize="12"
                                               FontWeight="Bold"/>
                                </Grid>
                                <ProgressBar Name="pbCpu" Height="8" Minimum="0" Maximum="100"
                                             Margin="0,10,0,8"
                                             Background="#E6F4F1" Foreground="#14B8A6"
                                             BorderThickness="0"/>
                                <TextBlock Name="txtCpuShort" Text="—"
                                           Style="{StaticResource MonoValue}"
                                           FontSize="11"/>
                            </StackPanel>
                        </Border>

                        <!-- RAM card -->
                        <Border Style="{StaticResource Card}" Margin="0,0,0,12">
                            <StackPanel>
                                <Grid>
                                    <TextBlock Text="RAM" Style="{StaticResource CardTitle}"
                                               Foreground="#1D4ED8"/>
                                    <TextBlock Name="txtRamPct" Text="—"
                                               HorizontalAlignment="Right"
                                               Foreground="#1D4ED8" FontSize="12"
                                               FontWeight="Bold"/>
                                </Grid>
                                <ProgressBar Name="pbRam" Height="8" Minimum="0" Maximum="100"
                                             Margin="0,10,0,8"
                                             Background="#E5EBFB" Foreground="#3B82F6"
                                             BorderThickness="0"/>
                                <TextBlock Name="txtRamShort" Text="—"
                                           Style="{StaticResource MonoValue}"
                                           FontSize="11"/>
                            </StackPanel>
                        </Border>

                        <!-- DISK card -->
                        <Border Style="{StaticResource Card}" Margin="0,0,0,12">
                            <StackPanel>
                                <Grid>
                                    <TextBlock Text="DISK" Style="{StaticResource CardTitle}"
                                               Foreground="#B45309"/>
                                    <TextBlock Name="txtDiskPct" Text="—"
                                               HorizontalAlignment="Right"
                                               Foreground="#B45309" FontSize="12"
                                               FontWeight="Bold"/>
                                </Grid>
                                <ProgressBar Name="pbDisk" Height="8" Minimum="0" Maximum="100"
                                             Margin="0,10,0,8"
                                             Background="#FBF0E1" Foreground="#F59E0B"
                                             BorderThickness="0"/>
                                <TextBlock Name="txtDiskShort" Text="—"
                                           Style="{StaticResource MonoValue}"
                                           FontSize="11"/>
                            </StackPanel>
                        </Border>

                        <!-- NETWORK card -->
                        <Border Style="{StaticResource Card}" Margin="0,0,0,12">
                            <StackPanel>
                                <TextBlock Text="NETWORK" Style="{StaticResource CardTitle}"
                                           Foreground="#6D28D9"/>
                                <Grid Margin="0,10,0,8">
                                    <Grid.ColumnDefinitions>
                                        <ColumnDefinition Width="*"/>
                                        <ColumnDefinition Width="6"/>
                                        <ColumnDefinition Width="*"/>
                                    </Grid.ColumnDefinitions>
                                    <StackPanel Grid.Column="0">
                                        <TextBlock Text="RX" Foreground="#8A94A6"
                                                   FontSize="9" FontWeight="Bold"/>
                                        <ProgressBar Name="pbNetRx" Height="6"
                                                     Minimum="0" Maximum="100"
                                                     Background="#EFE8FB" Foreground="#A855F7"
                                                     BorderThickness="0"/>
                                    </StackPanel>
                                    <StackPanel Grid.Column="2">
                                        <TextBlock Text="TX" Foreground="#8A94A6"
                                                   FontSize="9" FontWeight="Bold"/>
                                        <ProgressBar Name="pbNetTx" Height="6"
                                                     Minimum="0" Maximum="100"
                                                     Background="#EFE8FB" Foreground="#A855F7"
                                                     BorderThickness="0"/>
                                    </StackPanel>
                                </Grid>
                                <TextBlock Name="txtNetShort" Text="—"
                                           Style="{StaticResource MonoValue}"
                                           FontSize="11"/>
                            </StackPanel>
                        </Border>

                        <!-- System Information card -->
                        <Border Style="{StaticResource Card}">
                            <StackPanel>
                                <TextBlock Text="System Information"
                                           Style="{StaticResource CardTitle}"
                                           Margin="0,0,0,12"/>

                                <TextBlock Text="OPERATING SYSTEM"
                                           Style="{StaticResource SubtleLabel}"
                                           Foreground="#0E7490"
                                           Margin="0,0,0,4"/>
                                <TextBlock Name="txtOsVersion" Text="—"
                                           Style="{StaticResource MonoValue}"
                                           Margin="0,0,0,12"/>

                                <TextBlock Text="DATE / TIME"
                                           Style="{StaticResource SubtleLabel}"
                                           Foreground="#6D28D9"
                                           Margin="0,0,0,4"/>
                                <TextBlock Name="txtDateTime" Text="—"
                                           Style="{StaticResource MonoValue}"
                                           Margin="0,0,0,12"/>

                                <TextBlock Text="BOOT TIME / UPTIME"
                                           Style="{StaticResource SubtleLabel}"
                                           Foreground="#15803D"
                                           Margin="0,0,0,4"/>
                                <TextBlock Name="txtBootTime" Text="—"
                                           Style="{StaticResource MonoValue}"/>

                                <Button Name="btnRefreshTime" Content="Refresh"
                                        HorizontalAlignment="Right"
                                        Height="26" Padding="14,0"
                                        Margin="0,14,0,0"
                                        Background="#F1F5FB" Foreground="#2563EB"
                                        BorderThickness="0" Cursor="Hand"
                                        FontSize="11" FontWeight="SemiBold"/>
                            </StackPanel>
                        </Border>
                    </StackPanel>
                </ScrollViewer>

                <!-- RIGHT: sessions (full height) -->
                <Border Grid.Column="2" Style="{StaticResource Card}">
                    <Grid>
                        <Grid.RowDefinitions>
                            <RowDefinition Height="Auto"/>
                            <RowDefinition Height="Auto"/>
                            <RowDefinition Height="*"/>
                            <RowDefinition Height="Auto"/>
                        </Grid.RowDefinitions>

                        <Grid Grid.Row="0" Margin="0,0,0,12">
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="Auto"/>
                            </Grid.ColumnDefinitions>
                            <StackPanel Grid.Column="0">
                                <TextBlock Text="Remote Sessions (RDP)"
                                           Style="{StaticResource CardTitle}"
                                           Foreground="#B91C1C"/>
                                <TextBlock Text="Active and disconnected user sessions"
                                           Foreground="#8A94A6" FontSize="11"
                                           Margin="0,2,0,0"/>
                            </StackPanel>
                        </Grid>

                        <Grid Grid.Row="1" Margin="0,0,0,12">
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="Auto"/>
                                <ColumnDefinition Width="Auto"/>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="Auto"/>
                                <ColumnDefinition Width="Auto"/>
                            </Grid.ColumnDefinitions>

                            <TextBlock Grid.Column="0" Text="State:"
                                       Foreground="#7A8AA0" FontSize="11"
                                       VerticalAlignment="Center" Margin="0,0,6,0"/>
                            <ComboBox Grid.Column="1" Name="cmbStateFilter" Width="150" Height="28"
                                      Background="White" Foreground="#1F2933"
                                      BorderBrush="#D5DCE5" SelectedIndex="0"
                                      VerticalContentAlignment="Center">
                                <ComboBoxItem Content="All sessions"/>
                                <ComboBoxItem Content="Active only"/>
                                <ComboBoxItem Content="Disconnected only"/>
                            </ComboBox>

                            <StackPanel Grid.Column="3" Orientation="Horizontal">
                                <Button Name="btnCheckSession" Content="Refresh List"
                                        Height="28" Padding="14,0" Margin="0,0,6,0"
                                        Background="#0F766E" Foreground="White"
                                        BorderThickness="0" FontWeight="Bold"
                                        Cursor="Hand" FontSize="11"/>
                                <Button Name="btnCopyUsers" Content="Copy"
                                        Height="28" Padding="14,0"
                                        Background="#EEF1F5" Foreground="#334155"
                                        BorderThickness="0" Cursor="Hand"
                                        FontSize="11"/>
                            </StackPanel>
                        </Grid>

                        <ListBox Grid.Row="2" Name="lstSessions"
                                 Background="#F8FAFC"
                                 Foreground="#1F2933"
                                 BorderBrush="#E2E6EC" BorderThickness="1"
                                 FontFamily="Consolas" FontSize="12"
                                 SelectionMode="Single"
                                 ScrollViewer.HorizontalScrollBarVisibility="Auto"
                                 ScrollViewer.VerticalScrollBarVisibility="Auto">
                            <ListBox.ItemContainerStyle>
                                <Style TargetType="ListBoxItem">
                                    <Setter Property="Padding" Value="8,4"/>
                                    <Setter Property="HorizontalContentAlignment" Value="Left"/>
                                    <Setter Property="Background" Value="Transparent"/>
                                    <Style.Triggers>
                                        <Trigger Property="IsMouseOver" Value="True">
                                            <Setter Property="Background" Value="#EAF2FF"/>
                                        </Trigger>
                                        <Trigger Property="IsSelected" Value="True">
                                            <Setter Property="Background" Value="#DBEAFE"/>
                                        </Trigger>
                                    </Style.Triggers>
                                </Style>
                            </ListBox.ItemContainerStyle>
                            <ListBox.ItemTemplate>
                                <DataTemplate>
                                    <TextBlock Text="{Binding Display}"
                                               Foreground="{Binding Color}"
                                               FontFamily="Consolas"
                                               FontSize="12"/>
                                </DataTemplate>
                            </ListBox.ItemTemplate>
                        </ListBox>

                        <Grid Grid.Row="3" Margin="0,12,0,0">
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="Auto"/>
                            </Grid.ColumnDefinitions>
                            <TextBlock Grid.Column="0" Name="txtSelInfo"
                                       Text="No session selected."
                                       Foreground="#8A94A6" FontSize="11"
                                       VerticalAlignment="Center"
                                       TextWrapping="Wrap"/>
                            <Button Grid.Column="1" Name="btnDisconnect"
                                    Content="Disconnect Selected"
                                    Height="34" Padding="18,0"
                                    Background="#DC2626" Foreground="White"
                                    BorderThickness="0" FontWeight="Bold"
                                    Cursor="Hand" IsEnabled="False"
                                    FontSize="12"/>
                        </Grid>
                    </Grid>
                </Border>
            </Grid>
        </Grid>
    </Grid>
</Window>
"@

$reader = New-Object System.Xml.XmlNodeReader $xaml
$window = [Windows.Markup.XamlReader]::Load($reader)

$txtServer       = $window.FindName("txtServer")
$btnCheck        = $window.FindName("btnCheck")
$btnClear        = $window.FindName("btnClear")
$txtStatus       = $window.FindName("txtStatus")
$txtFooter       = $window.FindName("txtFooter")
$txtCpuPct       = $window.FindName("txtCpuPct")
$txtCpuShort     = $window.FindName("txtCpuShort")
$txtRamPct       = $window.FindName("txtRamPct")
$txtRamShort     = $window.FindName("txtRamShort")
$txtDiskPct      = $window.FindName("txtDiskPct")
$txtDiskShort    = $window.FindName("txtDiskShort")
$txtNetShort     = $window.FindName("txtNetShort")
$txtOsVersion    = $window.FindName("txtOsVersion")
$txtDateTime     = $window.FindName("txtDateTime")
$txtBootTime     = $window.FindName("txtBootTime")
$lstSessions     = $window.FindName("lstSessions")
$txtSelInfo      = $window.FindName("txtSelInfo")
$btnCheckSession = $window.FindName("btnCheckSession")
$btnCopyUsers    = $window.FindName("btnCopyUsers")
$btnDisconnect   = $window.FindName("btnDisconnect")
$btnRefreshTime  = $window.FindName("btnRefreshTime")
$cmbStateFilter  = $window.FindName("cmbStateFilter")
$pbCpu           = $window.FindName("pbCpu")
$pbRam           = $window.FindName("pbRam")
$pbDisk          = $window.FindName("pbDisk")
$pbNetRx         = $window.FindName("pbNetRx")
$pbNetTx         = $window.FindName("pbNetTx")

# ---------------- Shared state (thread-safe) ----------------
$script:SharedState = [hashtable]::Synchronized(@{
    ServerName     = $null
    UserData       = @()
    UsersText      = $null
    NonWindowsHint = $false
    LastTtl        = $null
})

# ===========================================================================
# Formatting helpers
# ===========================================================================
function Format-Bytes {
    param([double]$Bytes)
    if ($Bytes -ge 1TB) { return "{0:N2} TB" -f ($Bytes / 1TB) }
    if ($Bytes -ge 1GB) { return "{0:N2} GB" -f ($Bytes / 1GB) }
    if ($Bytes -ge 1MB) { return "{0:N2} MB" -f ($Bytes / 1MB) }
    if ($Bytes -ge 1KB) { return "{0:N2} KB" -f ($Bytes / 1KB) }
    return "{0:N0} B" -f $Bytes
}

function Format-BitsPerSec {
    param([double]$BitsPerSec)
    if ($BitsPerSec -ge 1Gb) { return "{0:N2} Gbps" -f ($BitsPerSec / 1Gb) }
    if ($BitsPerSec -ge 1Mb) { return "{0:N2} Mbps" -f ($BitsPerSec / 1Mb) }
    if ($BitsPerSec -ge 1Kb) { return "{0:N2} Kbps" -f ($BitsPerSec / 1Kb) }
    return "{0:N0} bps" -f $BitsPerSec
}

function Format-ServerDateTime {
    param(
        [datetime]$RemoteTime,
        [datetime]$LocalTime,
        [string]$TimeZoneId,
        [double]$UtcOffsetHours
    )

    $offset = $RemoteTime - $LocalTime
    $offsetStr = if ([math]::Abs($offset.TotalSeconds) -lt 1) {
        "0 s (in sync)"
    } else {
        $sign = if ($offset.TotalSeconds -ge 0) { "+" } else { "-" }
        $abs  = [timespan]::FromSeconds([math]::Abs($offset.TotalSeconds))
        "{0}{1:d2}h {2:d2}m {3:d2}s" -f $sign, [int]$abs.TotalHours, $abs.Minutes, $abs.Seconds
    }

    $utcSign = if ($UtcOffsetHours -ge 0) { "+" } else { "-" }
    $utcAbs  = [timespan]::FromHours([math]::Abs($UtcOffsetHours))
    $utcStr  = "UTC{0}{1:d2}:{2:d2}" -f $utcSign, [int]$utcAbs.TotalHours, $utcAbs.Minutes

    $tzLine = if ($TimeZoneId) { "$TimeZoneId  ($utcStr)" } else { $utcStr }

    return @"
Local time  : $($RemoteTime.ToString('yyyy-MM-dd HH:mm:ss'))
Time zone   : $tzLine
Offset vs PC: $offsetStr
"@
}

function Format-BootTime {
    param(
        [datetime]$LastBoot,
        [datetime]$CurrentTime
    )

    $uptime = $CurrentTime - $LastBoot
    if ($uptime.TotalSeconds -lt 0) { $uptime = [timespan]::Zero }

    $days    = [int]$uptime.Days
    $hours   = $uptime.Hours
    $minutes = $uptime.Minutes
    $seconds = $uptime.Seconds

    return @"
Last boot   : $($LastBoot.ToString('yyyy-MM-dd HH:mm:ss'))
Uptime      : ${days}d ${hours}h ${minutes}m ${seconds}s
"@
}

function Format-OSVersion {
    param(
        [string]$Caption,
        [string]$Version,
        [string]$BuildNumber,
        [string]$OSArchitecture,
        [string]$CSDVersion,
        [string]$InstallDate
    )

    $lines = @()
    if ($Caption)     { $lines += "OS        : $Caption" }
    $verLine = @()
    if ($Version)     { $verLine += "Version $Version" }
    if ($BuildNumber) { $verLine += "Build $BuildNumber" }
    if ($verLine.Count -gt 0) { $lines += "            " + ($verLine -join "  |  ") }
    if ($OSArchitecture) { $lines += "Arch      : $OSArchitecture" }
    if ($CSDVersion)  { $lines += "ServicePack: $CSDVersion" }
    if ($InstallDate) { $lines += "Installed : $InstallDate" }
    if ($lines.Count -eq 0) { $lines += "OS version information unavailable." }
    return ($lines -join "`n")
}

# ===========================================================================
# Resolve IP to hostname
# ===========================================================================
function Resolve-IfIP {
    param([string]$Server)
    if ([string]::IsNullOrWhiteSpace($Server)) { return $Server }
    $ip = $null
    if ([System.Net.IPAddress]::TryParse($Server.Trim(), [ref]$ip)) {
        try {
            $h = [System.Net.Dns]::GetHostEntry($Server.Trim()).HostName
            if ($h) { return $h.Split('.')[0] }
        } catch { }
    }
    return $Server
}

# ===========================================================================
# Ping TTL helper
# ===========================================================================
function Get-PingTtl {
    param([string]$Server)
    try {
        $out = & ping -4 -n 1 -w 1000 $Server 2>$null
        if (-not $out) { return $null }
        $text = ($out -join "`n")
        if ($text -match '(?i)TTL\s*=\s*(\d+)') { return [int]$matches[1] }
        return $null
    } catch { return $null }
}

# ===========================================================================
# Network throughput
# ===========================================================================
function Get-NetworkThroughput {
    param(
        [Microsoft.Management.Infrastructure.CimSession]$CimSession,
        [int]$SampleSeconds = 1
    )

    $adapters = Get-CimInstance -CimSession $CimSession -ClassName Win32_PerfRawData_Tcpip_NetworkInterface -ErrorAction Stop |
                Where-Object {
                    $_.Name -notmatch 'isatap|Loopback|Teredo|Pseudo|Tunnel|vEthernet|Virtual|Bluetooth|WAN Miniport'
                }

    if (-not $adapters) { throw "No active network adapters found." }

    $sample1 = @{}
    foreach ($a in $adapters) {
        $sample1[$a.Name] = @{
            BytesReceived = [double]$a.BytesReceivedPersec
            BytesSent     = [double]$a.BytesSentPersec
            Timestamp     = [double]$a.Timestamp_PerfTime
            Frequency     = [double]$a.Frequency_PerfTime
        }
    }

    Start-Sleep -Seconds $SampleSeconds

    $adapters2 = Get-CimInstance -CimSession $CimSession -ClassName Win32_PerfRawData_Tcpip_NetworkInterface -ErrorAction Stop |
                 Where-Object {
                     $_.Name -notmatch 'isatap|Loopback|Teredo|Pseudo|Tunnel|vEthernet|Virtual|Bluetooth|WAN Miniport'
                 }

    $results = @()
    foreach ($a in $adapters2) {
        if (-not $sample1.ContainsKey($a.Name)) { continue }

        $s1 = $sample1[$a.Name]
        $t1 = $s1.Timestamp / $s1.Frequency
        $t2 = [double]$a.Timestamp_PerfTime / [double]$a.Frequency_PerfTime
        $dt = $t2 - $t1
        if ($dt -le 0) { continue }

        $rxDelta = [double]$a.BytesReceivedPersec - $s1.BytesReceived
        $txDelta = [double]$a.BytesSentPersec     - $s1.BytesSent
        if ($rxDelta -lt 0) { $rxDelta = 0 }
        if ($txDelta -lt 0) { $txDelta = 0 }

        $rxBps = ($rxDelta / $dt) * 8
        $txBps = ($txDelta / $dt) * 8

        $linkSpeedBps = 0
        try {
            $adapterInfo = Get-CimInstance -CimSession $CimSession `
                           -ClassName Win32_NetworkAdapter -Filter "NetConnectionID='$($a.Name)'" `
                           -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($adapterInfo -and $adapterInfo.Speed) {
                $linkSpeedBps = [double]$adapterInfo.Speed
            }
        } catch { }

        $results += [PSCustomObject]@{
            Name         = $a.Name
            RxBps        = $rxBps
            TxBps        = $txBps
            LinkSpeedBps = $linkSpeedBps
            RxPercent    = if ($linkSpeedBps -gt 0) { [math]::Round(($rxBps / $linkSpeedBps) * 100, 2) } else { 0 }
            TxPercent    = if ($linkSpeedBps -gt 0) { [math]::Round(($txBps / $linkSpeedBps) * 100, 2) } else { 0 }
        }
    }

    return $results
}

# ===========================================================================
# Parser: quser output -> session objects
# ===========================================================================
function Parse-QuserOutput {
    param([string[]]$QuserLines)

    $out = @()
    if (-not $QuserLines) { return $out }

    $headerIdx = -1
    for ($i = 0; $i -lt $QuserLines.Count; $i++) {
        if ($QuserLines[$i] -match '(?i)USERNAME') { $headerIdx = $i; break }
    }
    if ($headerIdx -lt 0) { return $out }

    $header  = $QuserLines[$headerIdx]
    $colUser = $header.IndexOf("USERNAME")
    $colSess = $header.IndexOf("SESSIONNAME")
    $colId   = $header.IndexOf("ID")
    $colSt   = $header.IndexOf("STATE")
    $colIdle = $header.IndexOf("IDLE")
    $colTime = $header.IndexOf("LOGON")

    for ($i = $headerIdx + 1; $i -lt $QuserLines.Count; $i++) {
        $raw = $QuserLines[$i]
        if ([string]::IsNullOrWhiteSpace($raw)) { continue }
        if ($raw -match '(?i)No User exists') { continue }
        if ($raw -match '(?i)No users exist') { continue }

        $line = $raw.TrimEnd("`r","`n")
        $line = $line -replace "`t", " "

        $isCurrent = $false
        if ($line -match '^\s*>') {
            $isCurrent = $true
            $line = $line -replace '^\s*>\s*', '  '
        } else {
            $line = $line -replace '^\s*', '  '
        }

        if ($colUser -ge 0 -and $colSess -gt $colUser -and $colId -gt $colSess -and $colSt -gt $colId) {
            try {
                $userStr = if ($colSess -gt $colUser) { $line.Substring($colUser, $colSess - $colUser) } else { "" }
                $sessStr = if ($colId -gt $colSess)     { $line.Substring($colSess, $colId - $colSess) }     else { "" }
                $idStr   = if ($colSt -gt $colId)       { $line.Substring($colId, $colSt - $colId) }         else { "" }
                $stStr   = if ($colIdle -gt $colSt)     { $line.Substring($colSt, $colIdle - $colSt) }       else { "" }
                $rest    = if ($colTime -gt $colIdle -and $colIdle -gt 0) { $line.Substring($colIdle) } else { "" }
            } catch {
                $parts = ($line -replace '\s+', ' ').Trim() -split ' '
                if ($parts.Count -ge 5) {
                    $userStr = $parts[0]; $sessStr = $parts[1]; $idStr = $parts[2]; $stStr = $parts[3]
                    $rest    = ($parts[4..($parts.Count-1)] -join ' ')
                } else { continue }
            }

            $user = $userStr.Trim()
            $sess = $sessStr.Trim()
            $idTx = $idStr.Trim()
            $st   = $stStr.Trim()

            $rest  = $rest.Trim()
            $idle  = "-"
            $logon = $rest
            if ($rest -match '^(.*?)\s+((?:\d{1,4}[\/\-\.]\d{1,2}[\/\-\.]\d{1,4})\s+.*)$') {
                $idle  = $matches[1].Trim()
                $logon = $matches[2].Trim()
                if ([string]::IsNullOrWhiteSpace($idle)) { $idle = "." }
            } elseif ($rest -match '^\s*\.\s+(.+)$') {
                $idle  = "."
                $logon = $matches[1].Trim()
            }
        } else {
            $parts = ($line -replace '\s+', ' ').Trim() -split ' '
            if ($parts.Count -lt 5) { continue }
            $user = $parts[0]
            $sess = $parts[1]
            $idTx = $parts[2]
            $st   = $parts[3]
            $rest = ($parts[4..($parts.Count-1)] -join ' ').Trim()

            $idle  = "-"
            $logon = $rest
            if ($rest -match '^(.*?)\s+((?:\d{1,4}[\/\-\.]\d{1,2}[\/\-\.]\d{1,4})\s+.*)$') {
                $idle  = $matches[1].Trim()
                $logon = $matches[2].Trim()
                if ([string]::IsNullOrWhiteSpace($idle)) { $idle = "." }
            }
        }

        if ($idTx -notmatch '^\d+$') { continue }
        $sessionId = [int]$idTx

        $stateRaw = $st
        $displayState = switch -Regex ($st) {
            '^Active$' { 'Active' }
            '^Disc'    { 'Disconnected' }
            '^Listen'  { 'Listen' }
            default    { $st }
        }

        $out += [PSCustomObject]@{
            User      = $user
            SessionId = $sessionId
            State     = $displayState
            StateRaw  = $stateRaw
            Station   = $sess
            Idle      = $idle
            LogonTime = $logon
        }
    }

    return $out
}

# ===========================================================================
# Remote sessions - RDP only (quser primary, qwinsta fallback)
# ===========================================================================
function Get-RemoteSessions {
    param([string]$Server)

    $noisyUsers = @('SYSTEM', 'LOCAL SERVICE', 'NETWORK SERVICE',
                    'DWM-1', 'DWM-2', 'UMFD-0', 'UMFD-1', 'ANONYMOUS LOGON')

    $sessions = @()

    try {
        $quserRaw  = & quser /server:$Server 2>$null
        $quserExit = $LASTEXITCODE
        if ($quserRaw -and $quserExit -eq 0) {
            $parsed = Parse-QuserOutput -QuserLines $quserRaw
            foreach ($p in $parsed) {
                if ($noisyUsers -contains $p.User.ToUpper()) { continue }
                if ($p.StateRaw -ieq 'Listen') { continue }

                $isRdp        = $p.Station -match '(?i)^rdp-tcp'
                $isConsole    = $p.Station -match '(?i)^console$'
                $isDisc       = $p.State -ieq 'Disconnected'
                $stationEmpty = [string]::IsNullOrWhiteSpace($p.Station)

                if ($isConsole) { continue }
                if (-not ($isRdp -or ($isDisc -and $stationEmpty))) { continue }

                $sessions += $p
            }
        }
    } catch { }

    if (-not $sessions -or $sessions.Count -eq 0) {
        try {
            $qwinstaRaw  = & qwinsta /server:$Server 2>$null
            $qwinstaExit = $LASTEXITCODE
            if ($qwinstaRaw -and $qwinstaExit -eq 0) {
                for ($i = 1; $i -lt $qwinstaRaw.Count; $i++) {
                    $line = $qwinstaRaw[$i]
                    if ([string]::IsNullOrWhiteSpace($line)) { continue }
                    $parts = [regex]::Split($line.Trim(), '\s{2,}')
                    if ($parts.Count -lt 5) { continue }

                    $station  = $parts[0].TrimStart('>').Trim()
                    $user     = $parts[1].Trim()
                    $idTx     = $parts[2].Trim()
                    $stateRaw = $parts[3].Trim()

                    if ($idTx -notmatch '^\d+$') { continue }
                    if ($stateRaw -ieq 'Listen') { continue }
                    if ($noisyUsers -contains $user.ToUpper()) { continue }
                    if ([string]::IsNullOrWhiteSpace($user)) { continue }

                    $isRdp        = $station -match '(?i)^rdp-tcp'
                    $isConsole    = $station -match '(?i)^console$'
                    $isDisc       = $stateRaw -match '(?i)^Disc'
                    $stationEmpty = [string]::IsNullOrWhiteSpace($station)

                    if ($isConsole) { continue }
                    if (-not ($isRdp -or ($isDisc -and $stationEmpty))) { continue }

                    $displayState = switch -Regex ($stateRaw) {
                        '^Active$' { 'Active' }
                        '^Disc'    { 'Disconnected' }
                        default    { $stateRaw }
                    }

                    $sessions += [PSCustomObject]@{
                        User      = $user
                        SessionId = [int]$idTx
                        State     = $displayState
                        StateRaw  = $stateRaw
                        Station   = $station
                        Idle      = "-"
                        LogonTime = "-"
                    }
                }
            }
        } catch { }
    }

    return $sessions
}

# ===========================================================================
# Collect function source for injection into background runspaces
# ===========================================================================
function Get-SharedFunctionSource {
    $names = @(
        'Format-Bytes',
        'Format-BitsPerSec',
        'Format-ServerDateTime',
        'Format-BootTime',
        'Format-OSVersion',
        'Resolve-IfIP',
        'Get-PingTtl',
        'Get-NetworkThroughput',
        'Parse-QuserOutput',
        'Get-RemoteSessions'
    )
    $sb = New-Object System.Text.StringBuilder
    foreach ($n in $names) {
        $cmd = Get-Command -Name $n -CommandType Function -ErrorAction Stop
        [void]$sb.AppendLine("function $n {")
        [void]$sb.AppendLine($cmd.Definition)
        [void]$sb.AppendLine("}")
    }
    return $sb.ToString()
}

$script:FunctionSource = Get-SharedFunctionSource

# ===========================================================================
# Background worker helper
# ===========================================================================
function Start-BackgroundTask {
    param(
        [Parameter(Mandatory)][string]$ScriptText,
        [object[]]$Arguments = @(),
        [hashtable]$Globals = @{}
    )

    $runspace = [runspacefactory]::CreateRunspace()
    $runspace.ApartmentState = 'MTA'
    $runspace.ThreadOptions  = 'ReuseThread'
    $runspace.Open()

    foreach ($k in $Globals.Keys) {
        $runspace.SessionStateProxy.SetVariable($k, $Globals[$k])
    }

    $ps = [powershell]::Create()
    $ps.Runspace = $runspace
    [void]$ps.AddScript($ScriptText)
    foreach ($arg in $Arguments) { [void]$ps.AddArgument($arg) }

    $handle = $ps.BeginInvoke()

    $null = Register-ObjectEvent -InputObject $ps -EventName InvocationStateChanged -Action {
        param($sender, $e)
        if ($e.InvocationStateInfo.State -in 'Completed','Failed','Stopped') {
            try { $sender.Dispose() } catch { }
            try { $sender.Runspace.Close(); $sender.Runspace.Dispose() } catch { }
            Unregister-Event -SourceIdentifier $e.InvocationStateInfo.GetType().Name -ErrorAction SilentlyContinue
        }
    }

    return @{ PowerShell = $ps; Handle = $handle; Runspace = $runspace }
}

# ===========================================================================
# Reset UI
# ===========================================================================
function Reset-UI {
    $txtCpuPct.Text     = "—"
    $txtCpuShort.Text   = "—"
    $txtRamPct.Text     = "—"
    $txtRamShort.Text   = "—"
    $txtDiskPct.Text    = "—"
    $txtDiskShort.Text  = "—"
    $txtDiskShort.ToolTip = $null
    $txtNetShort.Text   = "—"
    $txtOsVersion.Text  = "—"
    $txtDateTime.Text   = "—"
    $txtBootTime.Text   = "—"
    $pbCpu.Value        = 0
    $pbRam.Value        = 0
    $pbDisk.Value       = 0
    $pbNetRx.Value      = 0
    $pbNetTx.Value      = 0
    $lstSessions.ItemsSource = $null
    $txtSelInfo.Text = "No session selected."
    $btnDisconnect.IsEnabled = $false

    $script:SharedState.ServerName     = $null
    $script:SharedState.UserData       = @()
    $script:SharedState.UsersText      = $null
    $script:SharedState.NonWindowsHint = $false
    $script:SharedState.LastTtl        = $null

    $cmbStateFilter.SelectedIndex = 0
}

# ===========================================================================
# Render sessions
# ===========================================================================
function Render-Sessions {
    param([string]$Filter = "All")

    $userData = $script:SharedState.UserData

    if (-not $userData -or @($userData).Count -eq 0) {
        $lstSessions.ItemsSource = @()
        $txtSelInfo.Text = "No remote (RDP) sessions currently connected."
        $script:SharedState.UsersText = $txtSelInfo.Text
        return
    }

    $all = $userData

    $filtered = switch ($Filter) {
        "Active only"       { $all | Where-Object { $_.StateRaw -ieq 'Active' } }
        "Disconnected only" { $all | Where-Object { $_.StateRaw -ieq 'Disc' -or $_.State -ieq 'Disconnected' } }
        default             { $all }
    }

    if (-not $filtered -or @($filtered).Count -eq 0) {
        $lstSessions.ItemsSource = @()
        $txtSelInfo.Text = "No sessions match the current filter ($Filter)."
        $script:SharedState.UsersText = $txtSelInfo.Text
        return
    }

    $sorted = $filtered | Sort-Object @{Expression={ $_.State -ieq 'Disconnected' }}, User

    $rows = @()
    $textLines = @()
    $textLines += ("{0,-22} {1,-8} {2,-14} {3,-18} {4,-10} {5}" -f "USER", "SESSION", "STATE", "STATION", "IDLE", "LOGON TIME")
    $textLines += ("-" * 100)

    foreach ($s in $sorted) {
        $userStr = [string]$s.User
        if ($userStr.Length -gt 22) { $userStr = $userStr.Substring(0, 22) }
        $statStr = [string]$s.Station
        if ($statStr.Length -gt 18) { $statStr = $statStr.Substring(0, 18) }

        $lineText = ("{0,-22} {1,-8} {2,-14} {3,-18} {4,-10} {5}" -f `
                    $userStr, $s.SessionId, $s.State, $statStr, $s.Idle, $s.LogonTime)

        $color = if ($s.State -ieq 'Disconnected') { "#9E9E9E" } else { "#2E7D32" }

        $rows += [PSCustomObject]@{
            Display = $lineText
            Color   = $color
            Session = $s
        }
        $textLines += $lineText
    }

    $activeCount = @($all | Where-Object { $_.State -ieq 'Active' }).Count
    $discCount   = @($all | Where-Object { $_.State -ieq 'Disconnected' }).Count
    $textLines += ""
    $textLines += ("Total: {0}  |  Active: {1}  |  Disconnected: {2}   [filter: {3}]" -f `
                    @($all).Count, $activeCount, $discCount, $Filter)

    $lstSessions.ItemsSource = $rows
    $script:SharedState.UsersText = $textLines -join "`n"

    $txtSelInfo.Text = ("Showing {0} session(s). Select a row to enable Disconnect." -f @($rows).Count)
    $btnDisconnect.IsEnabled = $false
}

# ---------------------------------------------------------------------------
# Pre-built UI-thread delegates
# ---------------------------------------------------------------------------
$script:RefreshSessionsAction = [action]{
    if ($script:SharedState.UserData -and @($script:SharedState.UserData).Count -gt 0) {
        Render-Sessions -Filter $cmbStateFilter.SelectedItem.Content
    } else {
        $lstSessions.ItemsSource = @()
        $txtSelInfo.Text = "No remote (RDP) sessions currently connected."
        $script:SharedState.UsersText = $txtSelInfo.Text
    }
}

$script:ReloadSessionsAction = [action]{
    if ($script:SharedState.ServerName) {
        Load-RemoteSessions
    }
}

# ===========================================================================
# Background script: Check Server
# ===========================================================================
$script:CheckServerScript = @'
param($ServerName)

Add-Type -AssemblyName Microsoft.Management.Infrastructure -ErrorAction SilentlyContinue
. ([scriptblock]::Create($FunctionSource))

function Update-UI {
    param([scriptblock]$Action)
    $Window.Dispatcher.Invoke($Action, [System.Windows.Threading.DispatcherPriority]::Background)
}

try {
    Update-UI {
        $Window.FindName('txtStatus').Text = "Connecting to '$ServerName'..."
        $Window.FindName('txtFooter').Text = 'Working...'
    }

    if (-not (Test-Connection -ComputerName $ServerName -Count 1 -Quiet -ErrorAction Stop)) {
        throw "Server '$ServerName' is not reachable (ping failed)."
    }

    # TTL heuristic
    $ttl = Get-PingTtl -Server $ServerName
    $SharedState.LastTtl = $ttl
    if ($null -ne $ttl -and $ttl -lt 100) {
        $SharedState.NonWindowsHint = $true
        Update-UI {
            $Window.FindName('txtStatus').Text =
                "⚠ '$ServerName' reports TTL=$ttl — likely Linux/non-Windows host. Resource queries may fail."
        }
    } else {
        $SharedState.NonWindowsHint = $false
    }

    # PHASE 1: sessions
    Update-UI {
        if (-not $SharedState.NonWindowsHint) {
            $Window.FindName('txtStatus').Text = "Querying RDP sessions on '$ServerName'..."
        }
        $Window.FindName('txtSelInfo').Text = 'Querying RDP sessions...'
    }

    try {
        $remote = Get-RemoteSessions -Server $ServerName
        $SharedState.UserData = @($remote)
        $SharedState.ServerName = $ServerName

        $Window.Dispatcher.Invoke($RefreshAction, [System.Windows.Threading.DispatcherPriority]::Background)

        $sessionCount = @($remote).Count
        Update-UI {
            if (-not $SharedState.NonWindowsHint) {
                $Window.FindName('txtStatus').Text = "Sessions loaded ($sessionCount). Querying resources..."
            }
            $Window.FindName('btnCheckSession').IsEnabled = $true
        }
    } catch {
        $msg = $_.Exception.Message
        Update-UI {
            $Window.FindName('txtSelInfo').Text = "Session query failed: $msg"
            if (-not $SharedState.NonWindowsHint) {
                $Window.FindName('txtStatus').Text = "Sessions failed. Continuing with resources..."
            }
        }
    }

    if ($SharedState.NonWindowsHint) {
        $timeStr = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        $ttlText = if ($null -ne $ttl) { "TTL=$ttl" } else { "TTL=?" }
        Update-UI {
            $Window.FindName('txtStatus').Text =
                "⚠ '$ServerName' appears to be a non-Windows host ($ttlText). Resource metrics skipped."
            $Window.FindName('txtFooter').Text =
                "Last check: $timeStr  |  Target: $ServerName  |  v2.1.3  |  ⚠ $ttlText (non-Windows?)"
        }
        return
    }

    # PHASE 2: resources (Windows only)
    Update-UI {
        $Window.FindName('txtStatus').Text = "Querying server resources on '$ServerName'..."
    }

    $cimSession = $null
    try {
        $cimSession = New-CimSession -ComputerName $ServerName -ErrorAction Stop
    } catch {
        $msg = $_.Exception.Message
        Update-UI {
            $Window.FindName('txtStatus').Text = "CIM connection failed: $msg"
            $Window.FindName('txtFooter').Text = "Failed at $(Get-Date -Format 'HH:mm:ss')"
        }
        return
    }

    # CPU
    try {
        $cpu = Get-CimInstance -CimSession $cimSession -ClassName Win32_Processor -ErrorAction Stop
        $cpuName = ($cpu | Select-Object -First 1).Name
        $cpuLoad = [math]::Round((($cpu | Measure-Object -Property LoadPercentage -Average).Average), 1)
        $cores   = ($cpu | Measure-Object -Property NumberOfCores -Sum).Sum
        $logical = ($cpu | Measure-Object -Property NumberOfLogicalProcessors -Sum).Sum
        $short   = "$cpuName`n$cores cores / $logical threads"
        Update-UI {
            $Window.FindName('txtCpuPct').Text   = "$cpuLoad%"
            $Window.FindName('txtCpuShort').Text = $short
            $Window.FindName('pbCpu').Value      = $cpuLoad
        }
    } catch {
        $msg = "CPU query failed: $($_.Exception.Message)"
        Update-UI { $Window.FindName('txtCpuShort').Text = $msg }
    }

    # RAM
    try {
        $os = Get-CimInstance -CimSession $cimSession -ClassName Win32_OperatingSystem -ErrorAction Stop
        $totalRam = [double]$os.TotalVisibleMemorySize * 1KB
        $freeRam  = [double]$os.FreePhysicalMemory     * 1KB
        $usedRam  = $totalRam - $freeRam
        $ramPct   = [math]::Round(($usedRam / $totalRam) * 100, 1)
        $ramShort = "$(Format-Bytes $usedRam) used / $(Format-Bytes $totalRam)`n$(Format-Bytes $freeRam) free"
        Update-UI {
            $Window.FindName('txtRamPct').Text   = "$ramPct%"
            $Window.FindName('txtRamShort').Text = $ramShort
            $Window.FindName('pbRam').Value      = $ramPct
        }
    } catch {
        $msg = "RAM query failed: $($_.Exception.Message)"
        Update-UI { $Window.FindName('txtRamShort').Text = $msg }
    }

    # Disk
    try {
        $disks = Get-CimInstance -CimSession $cimSession -ClassName Win32_LogicalDisk -Filter "DriveType=3" -ErrorAction Stop
        $lines = @()
        $maxPct = 0.0
        $shortParts = @()
        foreach ($d in $disks) {
            if ($d.Size -and $d.Size -gt 0) {
                $size = [double]$d.Size; $free = [double]$d.FreeSpace; $used = $size - $free
                $pct  = [math]::Round(($used / $size) * 100, 1)
                if ($pct -gt $maxPct) { $maxPct = $pct }
                $bar  = ("#" * [int]($pct / 5)).PadRight(20, '.')
                $lines += ("{0,-4} [{1}] {2,5}%  Used: {3,10} / {4,10}  (Free: {5})" -f `
                            $d.DeviceID, $bar, $pct, (Format-Bytes $used), (Format-Bytes $size), (Format-Bytes $free))
                $shortParts += ("{0} {1}%" -f $d.DeviceID, $pct)
            }
        }
        $diskText  = if ($lines.Count -eq 0) { "No fixed disks found." } else { ($lines -join "`n") }
        $diskShort = if ($shortParts.Count -eq 0) { "—" } else { ($shortParts -join "`n") }
        Update-UI {
            $Window.FindName('txtDiskPct').Text   = "$maxPct%"
            $Window.FindName('txtDiskShort').Text = $diskShort
            $Window.FindName('pbDisk').Value      = $maxPct

            $diskDetail = $Window.FindName('txtDiskShort')
            if ($diskDetail) { $diskDetail.ToolTip = $diskText }
        }
    } catch {
        $msg = "Disk query failed: $($_.Exception.Message)"
        Update-UI {
            $Window.FindName('txtDiskShort').Text   = $msg
            $Window.FindName('txtDiskShort').ToolTip = $msg
        }
    }

    # OS Version
    try {
        $osInfo = Get-CimInstance -CimSession $cimSession -ClassName Win32_OperatingSystem -ErrorAction Stop
        $installDate = "-"
        if ($osInfo.InstallDate) {
            try { $installDate = ([datetime]$osInfo.InstallDate).ToString('yyyy-MM-dd') } catch { }
        }
        $osText = Format-OSVersion `
                    -Caption        $osInfo.Caption `
                    -Version        $osInfo.Version `
                    -BuildNumber    $osInfo.BuildNumber `
                    -OSArchitecture $osInfo.OSArchitecture `
                    -CSDVersion     $osInfo.CSDVersion `
                    -InstallDate    $installDate
        Update-UI { $Window.FindName('txtOsVersion').Text = $osText }
    } catch {
        $msg = "OS version query failed: $($_.Exception.Message)"
        Update-UI { $Window.FindName('txtOsVersion').Text = $msg }
    }

    # Date / Time
    try {
        $osTime = Get-CimInstance -CimSession $cimSession `
                  -ClassName Win32_OperatingSystem -ErrorAction Stop

        $remoteTime = [datetime]$osTime.LocalDateTime

        $tzId     = $null
        $utcHours = 0.0
        try {
            $tz = Get-CimInstance -CimSession $cimSession `
                  -ClassName Win32_TimeZone -ErrorAction Stop
            $tzId     = $tz.Caption
            $utcHours = -([double]$tz.Bias / 60.0)
        } catch { }

        $localTime = Get-Date

        $dtText = Format-ServerDateTime `
                    -RemoteTime     $remoteTime `
                    -LocalTime      $localTime `
                    -TimeZoneId     $tzId `
                    -UtcOffsetHours $utcHours

        Update-UI { $Window.FindName('txtDateTime').Text = $dtText }
    } catch {
        $msg = "Date/Time query failed: $($_.Exception.Message)"
        Update-UI { $Window.FindName('txtDateTime').Text = $msg }
    }

    # Boot Time / Uptime
    try {
        $osBoot = Get-CimInstance -CimSession $cimSession `
                  -ClassName Win32_OperatingSystem -ErrorAction Stop

        $lastBoot = [datetime]$osBoot.LastBootUpTime
        $nowLocal = Get-Date

        $bootText = Format-BootTime -LastBoot $lastBoot -CurrentTime $nowLocal
        Update-UI { $Window.FindName('txtBootTime').Text = $bootText }
    } catch {
        $msg = "Boot time query failed: $($_.Exception.Message)"
        Update-UI { $Window.FindName('txtBootTime').Text = $msg }
    }

    # NETWORK (last, 1s sample)
    try {
        Update-UI { $Window.FindName('txtNetShort').Text = 'Sampling (1s)...' }
        $netStats = Get-NetworkThroughput -CimSession $cimSession -SampleSeconds 1

        if (-not $netStats -or @($netStats).Count -eq 0) {
            Update-UI { $Window.FindName('txtNetShort').Text = 'No active adapters.' }
        } else {
            $shortLines = @(); $totalRx = 0.0; $totalTx = 0.0; $totalLink = 0.0
            foreach ($n in $netStats) {
                $totalRx += $n.RxBps; $totalTx += $n.TxBps
                if ($n.LinkSpeedBps -gt 0) { $totalLink += $n.LinkSpeedBps }
            }
            $shortLines += ("↓ $(Format-BitsPerSec $totalRx)  ↑ $(Format-BitsPerSec $totalTx)")
            $shortLines += ("Adapters: $(@($netStats).Count)")
            $netShort = ($shortLines -join "`n")

            $rxPct = if ($totalLink -gt 0) { [math]::Min(100, [math]::Round(($totalRx / $totalLink) * 100, 1)) } else { [math]::Min(100, [math]::Round($totalRx / 10Mb, 1)) }
            $txPct = if ($totalLink -gt 0) { [math]::Min(100, [math]::Round(($totalTx / $totalLink) * 100, 1)) } else { [math]::Min(100, [math]::Round($totalTx / 10Mb, 1)) }

            Update-UI {
                $Window.FindName('txtNetShort').Text = $netShort
                $Window.FindName('pbNetRx').Value    = $rxPct
                $Window.FindName('pbNetTx').Value    = $txPct
            }
        }
    } catch {
        $msg = "Network query failed: $($_.Exception.Message)"
        Update-UI { $Window.FindName('txtNetShort').Text = $msg }
    }

    try { Remove-CimSession $cimSession -ErrorAction SilentlyContinue } catch { }

    $timeStr = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $ttlText = if ($null -ne $ttl) { "TTL=$ttl" } else { "" }
    Update-UI {
        $Window.FindName('txtStatus').Text = "Successfully queried '$ServerName'."
        $Window.FindName('txtFooter').Text = "Last check: $timeStr  |  Target: $ServerName  |  v2.1.3  |  $ttlText"
    }
}
catch {
    $msg = $_.Exception.Message
    Update-UI {
        $Window.FindName('txtStatus').Text = "Error: $msg"
        $Window.FindName('txtFooter').Text = "Failed at $(Get-Date -Format 'HH:mm:ss')"
    }
}
finally {
    Update-UI { $Window.FindName('btnCheck').IsEnabled = $true }
}
'@

# ===========================================================================
# Background script: Load RDP sessions
# ===========================================================================
$script:LoadSessionsScript = @'
param($ServerName)

Add-Type -AssemblyName Microsoft.Management.Infrastructure -ErrorAction SilentlyContinue
. ([scriptblock]::Create($FunctionSource))

function Update-UI {
    param([scriptblock]$Action)
    $Window.Dispatcher.Invoke($Action, [System.Windows.Threading.DispatcherPriority]::Background)
}

try {
    Update-UI { $Window.FindName('txtSelInfo').Text = 'Querying RDP sessions...' }

    $remote = Get-RemoteSessions -Server $ServerName
    $SharedState.UserData = @($remote)

    $Window.Dispatcher.Invoke($RefreshAction, [System.Windows.Threading.DispatcherPriority]::Background)

    $timeStr = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    Update-UI {
        $Window.FindName('txtFooter').Text = "RDP session list refreshed: $timeStr  |  Target: $ServerName  |  v2.1.3"
    }
}
catch {
    $msg = $_.Exception.Message
    Update-UI { $Window.FindName('txtSelInfo').Text = "Failed to query remote sessions: $msg" }
}
finally {
    Update-UI { $Window.FindName('btnCheckSession').IsEnabled = $true }
}
'@

# ===========================================================================
# Background script: Disconnect session
# ===========================================================================
$script:DisconnectScript = @'
param($ServerName, $SessionId, $UserName)

Add-Type -AssemblyName Microsoft.Management.Infrastructure -ErrorAction SilentlyContinue
. ([scriptblock]::Create($FunctionSource))

function Update-UI {
    param([scriptblock]$Action)
    $Window.Dispatcher.Invoke($Action, [System.Windows.Threading.DispatcherPriority]::Background)
}

try {
    $output = & logoff $SessionId /server:$ServerName 2>&1
    $exit   = $LASTEXITCODE

    if ($exit -eq 0) {
        $timeStr = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        Update-UI {
            $Window.FindName('txtStatus').Text = "Disconnected user '$UserName' (session $SessionId) from $ServerName."
            $Window.FindName('txtFooter').Text = "Disconnect at $timeStr  |  Target: $ServerName  |  v2.1.3"
        }
    } else {
        $msg = "Disconnect failed (exit $exit): $output"
        Update-UI { $Window.FindName('txtStatus').Text = $msg }
    }
}
catch {
    $msg = $_.Exception.Message
    Update-UI { $Window.FindName('txtStatus').Text = "Disconnect error: $msg" }
}
finally {
    Start-Sleep -Milliseconds 500
    Update-UI { $Window.FindName('btnDisconnect').IsEnabled = $true }
    try {
        $Window.Dispatcher.Invoke($ReloadAction, [System.Windows.Threading.DispatcherPriority]::Background)
    } catch { }
}
'@

# ===========================================================================
# Check-Server: dispatch background task
# ===========================================================================
function Check-Server {
    param([string]$Server)

    $Server = Resolve-IfIP -Server $Server

    Reset-UI
    $txtStatus.Text = "Connecting to '$Server'..."
    $txtFooter.Text = "Working..."

    $btnCheck.IsEnabled = $false

    Start-BackgroundTask -ScriptText $script:CheckServerScript `
        -Arguments @($Server) `
        -Globals @{
            Window         = $window
            SharedState    = $script:SharedState
            FunctionSource = $script:FunctionSource
            RefreshAction  = $script:RefreshSessionsAction
        } | Out-Null
}

# ===========================================================================
# Load-RemoteSessions: dispatch background task
# ===========================================================================
function Load-RemoteSessions {
    $server = $script:SharedState.ServerName
    if (-not $server) {
        $txtSelInfo.Text = "No server checked yet. Click 'Check Server' first."
        return
    }

    $server = Resolve-IfIP -Server $server

    $txtSelInfo.Text = "Querying RDP sessions..."
    $btnCheckSession.IsEnabled = $false

    Start-BackgroundTask -ScriptText $script:LoadSessionsScript `
        -Arguments @($server) `
        -Globals @{
            Window         = $window
            SharedState    = $script:SharedState
            FunctionSource = $script:FunctionSource
            RefreshAction  = $script:RefreshSessionsAction
        } | Out-Null
}

# ===========================================================================
# Confirmation dialog
# ===========================================================================
function Show-DisconnectConfirmation {
    param(
        [string]$Server,
        [PSCustomObject]$Session
    )

    $escUser    = [System.Security.SecurityElement]::Escape($Session.User)
    $escServer  = [System.Security.SecurityElement]::Escape($Server)
    $escState   = [System.Security.SecurityElement]::Escape($Session.State)
    $escLogon   = [System.Security.SecurityElement]::Escape([string]$Session.LogonTime)
    $escSession = [System.Security.SecurityElement]::Escape("ID $($Session.SessionId)  ($($Session.Station))")

    $stateColor = if ($Session.State -ieq 'Disconnected') { "#9E9E9E" } else { "#2E7D32" }

    $confirmXaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Confirm Disconnect" Height="470" Width="640"
        WindowStartupLocation="CenterOwner"
        ResizeMode="NoResize"
        SizeToContent="Manual"
        Background="#EEF1F5"
        ShowInTaskbar="False">
    <Grid Margin="22">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <TextBlock Grid.Row="0" Text="Disconnect this user?"
                   Foreground="#B45309" FontSize="20" FontWeight="Bold"
                   TextAlignment="Center" HorizontalAlignment="Center"/>

        <TextBlock Grid.Row="1" Margin="0,10,0,18" TextWrapping="Wrap"
                   Foreground="#616161" FontSize="12"
                   TextAlignment="Center" HorizontalAlignment="Center"
                   Text="The user will be forcibly logged off from the remote server. Any unsaved work may be lost. This action cannot be undone."/>

        <Border Grid.Row="2" Background="White" BorderBrush="#E2E6EC"
                BorderThickness="1" CornerRadius="10" Padding="18">
            <StackPanel>
                <TextBlock Text="USER TO DISCONNECT" Foreground="#8A94A6"
                           FontSize="11" FontWeight="Bold" Margin="0,0,0,6"/>
                <TextBlock Text="$escUser" Foreground="#C2410C"
                           FontSize="24" FontWeight="Bold" TextWrapping="Wrap"
                           Margin="0,0,0,18"/>

                <Grid>
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="110"/>
                        <ColumnDefinition Width="*"/>
                    </Grid.ColumnDefinitions>
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="Auto"/>
                    </Grid.RowDefinitions>

                    <TextBlock Grid.Row="0" Grid.Column="0" Text="Server:"
                               Foreground="#8A94A6" FontSize="13" Margin="0,4"/>
                    <TextBlock Grid.Row="0" Grid.Column="1" Text="$escServer"
                               Foreground="#2563EB" FontSize="13" FontWeight="Bold" Margin="0,4"
                               TextWrapping="Wrap"/>

                    <TextBlock Grid.Row="1" Grid.Column="0" Text="Session:"
                               Foreground="#8A94A6" FontSize="13" Margin="0,4"/>
                    <TextBlock Grid.Row="1" Grid.Column="1" Text="$escSession"
                               Foreground="#1F2933" FontSize="13" Margin="0,4"
                               TextWrapping="Wrap"/>

                    <TextBlock Grid.Row="2" Grid.Column="0" Text="State:"
                               Foreground="#8A94A6" FontSize="13" Margin="0,4"/>
                    <TextBlock Grid.Row="2" Grid.Column="1" Text="$escState"
                               Foreground="$stateColor" FontSize="13" FontWeight="Bold" Margin="0,4"
                               TextWrapping="Wrap"/>

                    <TextBlock Grid.Row="3" Grid.Column="0" Text="Logon:"
                               Foreground="#8A94A6" FontSize="13" Margin="0,4"/>
                    <TextBlock Grid.Row="3" Grid.Column="1" Text="$escLogon"
                               Foreground="#1F2933" FontSize="13" Margin="0,4"
                               TextWrapping="Wrap"/>
                </Grid>
            </StackPanel>
        </Border>

        <StackPanel Grid.Row="3" Orientation="Horizontal"
                    HorizontalAlignment="Right" Margin="0,18,0,0">
            <Button Name="btnCancel" Content="Cancel" Width="120" Height="36"
                    Margin="0,0,10,0" Background="#E2E6EC" Foreground="#334155"
                    BorderThickness="0" Cursor="Hand" FontSize="13"/>
            <Button Name="btnConfirm" Content="Disconnect" Width="150" Height="36"
                    Background="#DC2626" Foreground="White"
                    BorderThickness="0" FontWeight="Bold" Cursor="Hand" FontSize="13"/>
        </StackPanel>
    </Grid>
</Window>
"@

    [xml]$cxml = $confirmXaml
    $creader = New-Object System.Xml.XmlNodeReader $cxml
    $cwin = [Windows.Markup.XamlReader]::Load($creader)
    $cwin.Owner = $window

    $script:confirmResult = $false

    $cbtnCancel  = $cwin.FindName("btnCancel")
    $cbtnConfirm = $cwin.FindName("btnConfirm")

    $cbtnCancel.Add_Click({
        $script:confirmResult = $false
        $cwin.Close()
    })

    $cbtnConfirm.Add_Click({
        $script:confirmResult = $true
        $cwin.Close()
    })

    $cwin.ShowDialog() | Out-Null
    return $script:confirmResult
}

# ===========================================================================
# Disconnect-Session: dispatch background task
# ===========================================================================
function Disconnect-Session {
    param(
        [string]$Server,
        [PSCustomObject]$Session
    )

    $Server = Resolve-IfIP -Server $Server

    if ($null -eq $Session.SessionId -or $Session.SessionId -eq "-") {
        [System.Windows.MessageBox]::Show(
            "This session has no numeric session ID. Cannot logoff.",
            "Disconnect failed", 'OK', 'Warning') | Out-Null
        return
    }

    $btnDisconnect.IsEnabled = $false

    Start-BackgroundTask -ScriptText $script:DisconnectScript `
        -Arguments @($Server, $Session.SessionId, $Session.User) `
        -Globals @{
            Window         = $window
            SharedState    = $script:SharedState
            FunctionSource = $script:FunctionSource
            ReloadAction   = $script:ReloadSessionsAction
        } | Out-Null
}

# ===========================================================================
# Event handlers
# ===========================================================================
$btnCheck.Add_Click({
    $srv = $txtServer.Text.Trim()
    if ([string]::IsNullOrWhiteSpace($srv)) {
        $txtStatus.Text = "Please enter a server name."
        return
    }
    Check-Server -Server $srv
})

$btnClear.Add_Click({
    $txtServer.Text = ""
    Reset-UI
    $txtStatus.Text = "Enter a server name and click Check Server."
    $txtFooter.Text = "Ready"
})

$btnCheckSession.Add_Click({
    Load-RemoteSessions
})

$btnRefreshTime.Add_Click({
    if ($script:SharedState.ServerName) {
        Check-Server -Server $script:SharedState.ServerName
    } else {
        $txtStatus.Text = "Check a server first."
    }
})

$cmbStateFilter.Add_SelectionChanged({
    if ($script:SharedState.UserData -and @($script:SharedState.UserData).Count -gt 0) {
        $filter = $cmbStateFilter.SelectedItem.Content
        Render-Sessions -Filter $filter
    }
})

$lstSessions.Add_SelectionChanged({
    if ($lstSessions.SelectedItem) {
        $s = $lstSessions.SelectedItem.Session
        $txtSelInfo.Text = ("Selected: {0}  |  Session {1}  |  {2}" -f $s.User, $s.SessionId, $s.State)
        $btnDisconnect.IsEnabled = $true
    } else {
        $txtSelInfo.Text = "No session selected."
        $btnDisconnect.IsEnabled = $false
    }
})

$btnCopyUsers.Add_Click({
    if ($script:SharedState.UsersText) {
        try {
            [System.Windows.Clipboard]::SetText($script:SharedState.UsersText)
            $txtStatus.Text = "Remote session list copied to clipboard."
        } catch {
            $txtStatus.Text = "Clipboard error: $($_.Exception.Message)"
        }
    } else {
        $txtStatus.Text = "Nothing to copy. Check Session first."
    }
})

$btnDisconnect.Add_Click({
    $selected = @($lstSessions.SelectedItems)
    if ($selected.Count -ne 1) {
        $txtStatus.Text = "Select exactly one session to disconnect."
        return
    }

    $session = $selected[0].Session
    $server  = $script:SharedState.ServerName

    $confirmed = Show-DisconnectConfirmation -Server $server -Session $session
    if (-not $confirmed) {
        $txtStatus.Text = "Disconnect cancelled."
        return
    }

    Disconnect-Session -Server $server -Session $session
})

$txtServer.Add_KeyDown({
    if ($_.Key -eq [System.Windows.Input.Key]::Enter) {
        $btnCheck.RaiseEvent((New-Object System.Windows.RoutedEventArgs([System.Windows.Controls.Button]::ClickEvent)))
    }
})

# ===========================================================================
# ps2exe / host cleanup
#   Force-terminate the hosting process when the window closes.
#   Without this, the ps2exe-wrapped EXE can linger in Task Manager after
#   the WPF window disappears, because background runspaces keep the host
#   process alive.
# ===========================================================================
$window.Add_Closed({
    try {
        [System.Diagnostics.Process]::GetCurrentProcess().Kill()
    } catch { }
})

# Show window
$window.ShowDialog() | Out-Null

# Safety net: if the Closed handler somehow didn't run (e.g. ShowDialog
# returned for another reason), exit the host explicitly.
try {
    [System.Diagnostics.Process]::GetCurrentProcess().Kill()
} catch { }