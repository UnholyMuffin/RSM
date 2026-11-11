# Remote Server Monitor - WPF GUI
# Version 2.3.0 - Overview removed; sortable session columns; multi-select disconnect

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase

# ---------------- Main window XAML ----------------
[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Remote Server Monitor v2.3.0" Height="900" Width="1420"
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
                    <TextBlock Text="v2.3.0" Foreground="#5B6B7F"
                               FontSize="10" Margin="0,2,0,0"/>
                </StackPanel>

                <StackPanel Grid.Row="1">
                    <TextBlock Text="TARGET HOSTNAME" Foreground="#7A8AA0"
                               FontSize="10" FontWeight="Bold" Margin="0,0,0,6"/>
                    <Border Background="#121A24" CornerRadius="6" Padding="2">
                        <TextBox Name="txtServer" Height="32" FontSize="13"
                                 Background="#121A24" Foreground="#E6ECF4"
                                 BorderThickness="0" Padding="10,4"
                                 VerticalContentAlignment="Center"
                                 CaretBrush="#5B9BFF"/>
                    </Border>

                    <Button Name="btnCheck" Content="SHOW STATUS"
                            Height="36" Margin="0,10,0,0"
                            Style="{StaticResource PrimaryButton}"/>

                    <Button Name="btnClear" Content="Clear"
                            Height="30" Margin="0,8,0,0"
                            Style="{StaticResource GhostButton}"/>
                </StackPanel>

                <!-- QUICK ACTIONS (compact) -->
                <StackPanel Grid.Row="2" Margin="0,18,0,0">
                    <TextBlock Text="QUICK ACTIONS" Foreground="#7A8AA0"
                               FontSize="10" FontWeight="Bold" Margin="0,0,0,6"/>

                    <Button Name="btnRdpConnect"
                            Content="Start RDP Connection"
                            Height="26" Margin="0,0,0,4"
                            Style="{StaticResource GhostButton}"
                            FontSize="10.5" FontWeight="SemiBold"
                            IsEnabled="False"
                            HorizontalContentAlignment="Center"/>

                    <Button Name="btnRemoteServices"
                            Content="Access Remote Services"
                            Height="26" Margin="0,0,0,4"
                            Style="{StaticResource GhostButton}"
                            FontSize="10.5" FontWeight="SemiBold"
                            IsEnabled="False"
                            HorizontalContentAlignment="Center"/>

                    <Button Name="btnSmbCShare"
                            Content="Explore SMB File System"
                            Height="26"
                            Style="{StaticResource GhostButton}"
                            FontSize="10.5" FontWeight="SemiBold"
                            IsEnabled="False"
                            HorizontalContentAlignment="Center"/>

                    <TextBlock Name="txtActionsHint"
                               Text="Check a server first."
                               Foreground="#5B6B7F" FontSize="10"
                               TextWrapping="Wrap" Margin="0,8,0,0"/>
                </StackPanel>

                <!-- PORT CHECK -->
                <StackPanel Grid.Row="3" Margin="0,18,0,0">
                    <TextBlock Text="PORT CHECK" Foreground="#7A8AA0"
                               FontSize="10" FontWeight="Bold" Margin="0,0,0,6"/>

                    <Grid>
                        <Grid.ColumnDefinitions>
                            <ColumnDefinition Width="*"/>
                            <ColumnDefinition Width="6"/>
                            <ColumnDefinition Width="Auto"/>
                        </Grid.ColumnDefinitions>

                        <Border Grid.Column="0" Background="#121A24" CornerRadius="6" Padding="2">
                            <TextBox Name="txtPort" Height="26" FontSize="12"
                                     Background="#121A24" Foreground="#E6ECF4"
                                     BorderThickness="0" Padding="10,4"
                                     VerticalContentAlignment="Center"
                                     CaretBrush="#5B9BFF"
                                     Text="443"/>
                        </Border>

                        <Button Grid.Column="2" Name="btnTryPort" Content="TEST"
                                Height="26" Padding="12,0"
                                Style="{StaticResource GhostButton}"
                                FontSize="10.5" FontWeight="SemiBold"
                                HorizontalContentAlignment="Center"/>
                    </Grid>

                    <TextBlock Name="txtPortResult" Text=""
                               FontSize="12" TextWrapping="Wrap"
                               FontWeight="Normal"
                               Margin="0,8,0,0"/>
                </StackPanel>

                <StackPanel Grid.Row="5">
                    <TextBlock Text="SUMMARY" Foreground="#7A8AA0"
                               FontSize="10" FontWeight="Bold" Margin="0,0,0,8"/>
                    <Border Background="#121A24" CornerRadius="6" Padding="12">
                        <StackPanel>
                            <TextBlock Name="txtStatus"
                                       Text="Enter a server name and click Check."
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
            <Grid>
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

                                <TextBlock Text="HOSTNAME (IP)"
                                           Style="{StaticResource SubtleLabel}"
                                           Foreground="#2563EB"
                                           Margin="0,0,0,4"/>
                                <TextBlock Name="txtHostIp" Text="—"
                                           Style="{StaticResource MonoValue}"
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

                        <!-- FILTER ROW: Search (left) | State | spacer | Refresh -->
                        <Grid Grid.Row="1" Margin="0,0,0,12">
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="Auto"/>
                                <ColumnDefinition Width="170"/>
                                <ColumnDefinition Width="Auto"/>
                                <ColumnDefinition Width="150"/>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="Auto"/>
                            </Grid.ColumnDefinitions>

                            <TextBlock Grid.Column="0" Text="Search:"
                                       Foreground="#7A8AA0" FontSize="11"
                                       VerticalAlignment="Center" Margin="0,0,6,0"/>
                            <Border Grid.Column="1" Background="White"
                                    BorderBrush="#D5DCE5" BorderThickness="1"
                                    CornerRadius="4"
                                    ToolTip="Filter sessions by username (substring, case-insensitive)">
                                <TextBox Name="txtSearchUser" Height="26"
                                         BorderThickness="0" Background="Transparent"
                                         Padding="8,0" VerticalContentAlignment="Center"
                                         FontSize="12" Foreground="#1F2933"
                                         CaretBrush="#2563EB"/>
                            </Border>

                            <TextBlock Grid.Column="2" Text="State:"
                                       Foreground="#7A8AA0" FontSize="11"
                                       VerticalAlignment="Center" Margin="14,0,6,0"/>
                            <ComboBox Grid.Column="3" Name="cmbStateFilter" Height="28"
                                      Background="White" Foreground="#1F2933"
                                      BorderBrush="#D5DCE5" SelectedIndex="0"
                                      VerticalContentAlignment="Center">
                                <ComboBoxItem Content="All sessions"/>
                                <ComboBoxItem Content="Active only"/>
                                <ComboBoxItem Content="Disconnected only"/>
                            </ComboBox>

                            <Button Grid.Column="5" Name="btnCheckSession" Content="Refresh List"
                                    Height="28" Padding="14,0"
                                    Background="#0F766E" Foreground="White"
                                    BorderThickness="0" FontWeight="Bold"
                                    Cursor="Hand" FontSize="11"/>
                        </Grid>

                        <!-- ============ sessions table: header + list ============ -->
                        <Grid Grid.Row="2">
                            <Grid.RowDefinitions>
                                <RowDefinition Height="Auto"/>
                                <RowDefinition Height="*"/>
                            </Grid.RowDefinitions>

                            <!-- Column header row (clickable to sort) -->
                            <Border Grid.Row="0" Background="#EDF0F4"
                                    BorderBrush="#D5DCE5" BorderThickness="1,1,1,0"
                                    CornerRadius="6,6,0,0">
                                <Grid>
                                    <Grid.ColumnDefinitions>
                                        <ColumnDefinition Width="150"/>
                                        <ColumnDefinition Width="65"/>
                                        <ColumnDefinition Width="105"/>
                                        <ColumnDefinition Width="160"/>
                                        <ColumnDefinition Width="95"/>
                                        <ColumnDefinition Width="*"/>
                                    </Grid.ColumnDefinitions>

                                    <Border Grid.Column="0" BorderBrush="#D5DCE5" BorderThickness="0,0,1,0">
                                        <Button Name="hdrUser" Tag="User" Content="USER"
                                                Background="Transparent" BorderThickness="0" Cursor="Hand"
                                                FontWeight="Bold" FontSize="10" Foreground="#4A5568"
                                                Padding="10,7" HorizontalContentAlignment="Left"/>
                                    </Border>
                                    <Border Grid.Column="1" BorderBrush="#D5DCE5" BorderThickness="0,0,1,0">
                                        <Button Name="hdrSession" Tag="SessionId" Content="SESSION"
                                                Background="Transparent" BorderThickness="0" Cursor="Hand"
                                                FontWeight="Bold" FontSize="10" Foreground="#4A5568"
                                                Padding="10,7" HorizontalContentAlignment="Left"/>
                                    </Border>
                                    <Border Grid.Column="2" BorderBrush="#D5DCE5" BorderThickness="0,0,1,0">
                                        <Button Name="hdrState" Tag="State" Content="STATE"
                                                Background="Transparent" BorderThickness="0" Cursor="Hand"
                                                FontWeight="Bold" FontSize="10" Foreground="#4A5568"
                                                Padding="10,7" HorizontalContentAlignment="Left"/>
                                    </Border>
                                    <Border Grid.Column="3" BorderBrush="#D5DCE5" BorderThickness="0,0,1,0">
                                        <Button Name="hdrClient" Tag="Client" Content="CLIENT"
                                                Background="Transparent" BorderThickness="0" Cursor="Hand"
                                                FontWeight="Bold" FontSize="10" Foreground="#4A5568"
                                                Padding="10,7" HorizontalContentAlignment="Left"/>
                                    </Border>
                                    <Border Grid.Column="4" BorderBrush="#D5DCE5" BorderThickness="0,0,1,0">
                                        <Button Name="hdrIdle" Tag="Idle" Content="IDLE"
                                                Background="Transparent" BorderThickness="0" Cursor="Hand"
                                                FontWeight="Bold" FontSize="10" Foreground="#4A5568"
                                                Padding="10,7" HorizontalContentAlignment="Left"/>
                                    </Border>
                                    <Border Grid.Column="5">
                                        <Button Name="hdrLogon" Tag="LogonTime" Content="LOGON TIME"
                                                Background="Transparent" BorderThickness="0" Cursor="Hand"
                                                FontWeight="Bold" FontSize="10" Foreground="#4A5568"
                                                Padding="10,7" HorizontalContentAlignment="Left"/>
                                    </Border>
                                </Grid>
                            </Border>

                            <!-- Session list (multi-select via Ctrl/Shift) -->
                            <ListBox Grid.Row="1" Name="lstSessions"
                                     Background="#F8FAFC"
                                     Foreground="#1F2933"
                                     BorderBrush="#D5DCE5" BorderThickness="1,0,1,1"
                                     FontFamily="Consolas" FontSize="12"
                                     SelectionMode="Extended"
                                     HorizontalContentAlignment="Stretch"
                                     ScrollViewer.HorizontalScrollBarVisibility="Disabled"
                                     ScrollViewer.VerticalScrollBarVisibility="Auto">
                                <ListBox.ItemContainerStyle>
                                    <Style TargetType="ListBoxItem">
                                        <Setter Property="Padding" Value="0"/>
                                        <Setter Property="HorizontalContentAlignment" Value="Stretch"/>
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
                                        <Grid>
                                            <Grid.ColumnDefinitions>
                                                <ColumnDefinition Width="150"/>
                                                <ColumnDefinition Width="65"/>
                                                <ColumnDefinition Width="105"/>
                                                <ColumnDefinition Width="160"/>
                                                <ColumnDefinition Width="95"/>
                                                <ColumnDefinition Width="*"/>
                                            </Grid.ColumnDefinitions>

                                            <Border Grid.Column="0" BorderBrush="#E2E6EC" BorderThickness="0,0,1,0" Padding="10,4">
                                                <TextBlock Text="{Binding User}" VerticalAlignment="Center"
                                                           TextTrimming="CharacterEllipsis"
                                                           Foreground="{Binding Color}"/>
                                            </Border>
                                            <Border Grid.Column="1" BorderBrush="#E2E6EC" BorderThickness="0,0,1,0" Padding="10,4">
                                                <TextBlock Text="{Binding SessionId}" VerticalAlignment="Center"
                                                           Foreground="{Binding Color}"/>
                                            </Border>
                                            <Border Grid.Column="2" BorderBrush="#E2E6EC" BorderThickness="0,0,1,0" Padding="10,4">
                                                <TextBlock Text="{Binding State}" VerticalAlignment="Center"
                                                           FontWeight="SemiBold"
                                                           Foreground="{Binding Color}"/>
                                            </Border>
                                            <Border Grid.Column="3" BorderBrush="#E2E6EC" BorderThickness="0,0,1,0" Padding="10,4">
                                                <TextBlock Text="{Binding Client}" VerticalAlignment="Center"
                                                           TextTrimming="CharacterEllipsis"
                                                           ToolTip="{Binding ClientAddress}"
                                                           Foreground="{Binding Color}"/>
                                            </Border>
                                            <Border Grid.Column="4" BorderBrush="#E2E6EC" BorderThickness="0,0,1,0" Padding="10,4">
                                                <TextBlock Text="{Binding Idle}" VerticalAlignment="Center"
                                                           Foreground="{Binding Color}"/>
                                            </Border>
                                            <Border Grid.Column="5" Padding="10,4">
                                                <TextBlock Text="{Binding LogonTime}" VerticalAlignment="Center"
                                                           TextTrimming="CharacterEllipsis"
                                                           Foreground="{Binding Color}"/>
                                            </Border>
                                        </Grid>
                                    </DataTemplate>
                                </ListBox.ItemTemplate>
                            </ListBox>
                        </Grid>

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

$txtServer         = $window.FindName("txtServer")
$btnCheck          = $window.FindName("btnCheck")
$btnClear          = $window.FindName("btnClear")
$txtStatus         = $window.FindName("txtStatus")
$txtFooter         = $window.FindName("txtFooter")
$txtCpuPct         = $window.FindName("txtCpuPct")
$txtCpuShort       = $window.FindName("txtCpuShort")
$txtRamPct         = $window.FindName("txtRamPct")
$txtRamShort       = $window.FindName("txtRamShort")
$txtDiskPct        = $window.FindName("txtDiskPct")
$txtDiskShort      = $window.FindName("txtDiskShort")
$txtNetShort       = $window.FindName("txtNetShort")
$txtHostIp         = $window.FindName("txtHostIp")
$txtOsVersion      = $window.FindName("txtOsVersion")
$txtDateTime       = $window.FindName("txtDateTime")
$txtBootTime       = $window.FindName("txtBootTime")
$lstSessions       = $window.FindName("lstSessions")
$txtSelInfo        = $window.FindName("txtSelInfo")
$btnCheckSession   = $window.FindName("btnCheckSession")
$btnDisconnect     = $window.FindName("btnDisconnect")
$btnRefreshTime    = $window.FindName("btnRefreshTime")
$cmbStateFilter    = $window.FindName("cmbStateFilter")
$txtSearchUser     = $window.FindName("txtSearchUser")
$pbCpu             = $window.FindName("pbCpu")
$pbRam             = $window.FindName("pbRam")
$pbDisk            = $window.FindName("pbDisk")
$pbNetRx           = $window.FindName("pbNetRx")
$pbNetTx           = $window.FindName("pbNetTx")
$btnRdpConnect     = $window.FindName("btnRdpConnect")
$btnRemoteServices = $window.FindName("btnRemoteServices")
$btnSmbCShare      = $window.FindName("btnSmbCShare")
$txtActionsHint    = $window.FindName("txtActionsHint")
$txtPort           = $window.FindName("txtPort")
$btnTryPort        = $window.FindName("btnTryPort")
$txtPortResult     = $window.FindName("txtPortResult")
$hdrUser           = $window.FindName("hdrUser")
$hdrSession        = $window.FindName("hdrSession")
$hdrState          = $window.FindName("hdrState")
$hdrClient         = $window.FindName("hdrClient")
$hdrIdle           = $window.FindName("hdrIdle")
$hdrLogon          = $window.FindName("hdrLogon")

# ---------------- Shared state (thread-safe) ----------------
$script:SharedState = [hashtable]::Synchronized(@{
    ServerName     = $null
    UserData       = @()
    NonWindowsHint = $false
    LastTtl        = $null
})

# ---------------- Sort state ----------------
$script:SortColumn    = $null
$script:SortAscending = $true

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

function Format-HostIp {
    param(
        [string]$HostName,
        [string[]]$IpAddresses
    )

    $name = if ($HostName) { $HostName } else { "unknown" }
    $ips  = @($IpAddresses |
             Where-Object { $_ -and $_ -notmatch '^(127\.|169\.254\.|::1|fe80:)' } |
             Select-Object -Unique)

    if ($ips.Count -eq 0) {
        return "$name  (no IP resolved)"
    }
    return ("{0}  ({1})" -f $name, ($ips -join ", "))
}

# ---------------------------------------------------------------------------
# Idle time: parse quser's raw IDLE TIME value into minutes
#   "."        -> 0        (user is actively inputting)
#   "none"     -> $null    (quser could not report it)
#   "-" / ""   -> $null    (qwinsta fallback)
#   "12"       -> 12 min
#   "1:23"     -> 1 h 23 m
#   "1+2:34"   -> 1 d 2 h 34 m
# ---------------------------------------------------------------------------
function ConvertTo-IdleMinutes {
    param([string]$Value)

    if ([string]::IsNullOrWhiteSpace($Value)) { return $null }
    $v = $Value.Trim()

    if ($v -eq '.') { return 0.0 }
    if ($v -match '(?i)^(none|n/a|-|—)$') { return $null }

    if ($v -match '^(?:(\d+)\+)?(\d{1,3})(?::(\d{1,2}))?$') {
        $days  = if ($matches[1]) { [double]$matches[1] } else { 0 }
        if ($matches[3]) {
            $hours = [double]$matches[2]
            $mins  = [double]$matches[3]
        } else {
            $hours = 0
            $mins  = [double]$matches[2]   # bare number = minutes
        }
        return ($days * 1440 + $hours * 60 + $mins)
    }
    return $null
}

# ---------------------------------------------------------------------------
# Idle time: minutes -> "Xd Yh Zm" (leading zero components omitted)
#   $null -> "—"   ;   0 -> "0m"   ;   90 -> "1h 30m"   ;   1500 -> "1d 1h 0m"
# ---------------------------------------------------------------------------
function Format-IdleDuration {
    param([object]$Minutes)

    if ($null -eq $Minutes) { return "—" }

    $total = [int][math]::Floor([double]$Minutes)
    if ($total -lt 0) { $total = 0 }

    $d = [int][math]::Floor($total / 1440)
    $h = [int][math]::Floor(($total % 1440) / 60)
    $m = $total % 60

    $parts = @()
    if ($d -gt 0) { $parts += "${d}d" }
    if ($h -gt 0 -or $d -gt 0) { $parts += "${h}h" }
    $parts += "${m}m"
    return ($parts -join ' ')
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
# WTS API helper: RDP client name + IP per session
# ===========================================================================
function Initialize-WtsHelper {
    if ('RemoteMonitor.WtsHelper' -as [type]) { return }

    $cs = @"
using System;
using System.Runtime.InteropServices;

namespace RemoteMonitor {
    public static class WtsHelper {
        [DllImport("wtsapi32.dll", EntryPoint = "WTSOpenServerA",
                   SetLastError = true, CharSet = CharSet.Ansi)]
        private static extern IntPtr WTSOpenServerA(string pServerName);

        [DllImport("wtsapi32.dll")]
        private static extern void WTSCloseServer(IntPtr hServer);

        [DllImport("wtsapi32.dll", EntryPoint = "WTSQuerySessionInformationA",
                   SetLastError = true)]
        private static extern bool WTSQuerySessionInformationA(
            IntPtr hServer, int sessionId, int wtsInfoClass,
            out IntPtr ppBuffer, out int pBytesReturned);

        [DllImport("wtsapi32.dll")]
        private static extern void WTSFreeMemory(IntPtr pMemory);

        private const int WTSClientName    = 10;
        private const int WTSClientAddress = 14;
        private const int AF_INET          = 2;

        private static string[] QueryOne(IntPtr hServer, int sessionId) {
            string[] result = new string[] { null, null };

            IntPtr buffer = IntPtr.Zero; int bytes = 0;
            try {
                if (WTSQuerySessionInformationA(hServer, sessionId,
                        WTSClientName, out buffer, out bytes)
                    && buffer != IntPtr.Zero) {
                    result[0] = Marshal.PtrToStringAnsi(buffer);
                }
            } finally {
                if (buffer != IntPtr.Zero) { WTSFreeMemory(buffer); }
            }

            buffer = IntPtr.Zero; bytes = 0;
            try {
                if (WTSQuerySessionInformationA(hServer, sessionId,
                        WTSClientAddress, out buffer, out bytes)
                    && buffer != IntPtr.Zero) {

                    int family = Marshal.ReadInt32(buffer, 0);
                    if (family == AF_INET) {
                        byte[] raw = new byte[20];
                        Marshal.Copy(new IntPtr(buffer.ToInt64() + 4), raw, 0, 20);

                        byte b0 = raw[4], b1 = raw[5], b2 = raw[6], b3 = raw[7];
                        if (b0 == 0 && b1 == 0 && b2 == 0 && b3 == 0) {
                            b0 = raw[0]; b1 = raw[1]; b2 = raw[2]; b3 = raw[3];
                        }
                        if (!(b0 == 0 && b1 == 0 && b2 == 0 && b3 == 0)) {
                            result[1] = string.Format("{0}.{1}.{2}.{3}", b0, b1, b2, b3);
                        }
                    }
                }
            } finally {
                if (buffer != IntPtr.Zero) { WTSFreeMemory(buffer); }
            }
            return result;
        }

        public static string[][] QueryAllClients(string server, int[] sessionIds) {
            string[][] results = new string[sessionIds.Length][];
            IntPtr hServer = IntPtr.Zero;
            try {
                hServer = WTSOpenServerA(server);
                if (hServer == IntPtr.Zero) {
                    for (int i = 0; i < sessionIds.Length; i++)
                        results[i] = new string[] { null, null };
                    return results;
                }
                for (int i = 0; i < sessionIds.Length; i++)
                    results[i] = QueryOne(hServer, sessionIds[i]);
            } finally {
                if (hServer != IntPtr.Zero) { WTSCloseServer(hServer); }
            }
            return results;
        }
    }
}
"@
    Add-Type -TypeDefinition $cs -ErrorAction SilentlyContinue
}

function Get-RdpClientInfo {
    param(
        [string]$Server,
        [int[]]$SessionIds
    )

    $map = @{}
    if (-not $SessionIds -or $SessionIds.Count -eq 0) { return $map }

    $ids = @($SessionIds | Select-Object -Unique)

    try { Initialize-WtsHelper } catch { }
    if (-not ('RemoteMonitor.WtsHelper' -as [type])) {
        foreach ($sid in $ids) {
            $map[[int]$sid] = [PSCustomObject]@{ Name = ""; Address = "" }
        }
        return $map
    }

    $target = if ([string]::IsNullOrWhiteSpace($Server)) { $env:COMPUTERNAME } else { $Server }

    $rows = $null
    try { $rows = [RemoteMonitor.WtsHelper]::QueryAllClients($target, [int[]]$ids) } catch { }

    for ($i = 0; $i -lt $ids.Count; $i++) {
        $sid  = [int]$ids[$i]
        $name = ""; $addr = ""
        if ($rows -and $i -lt $rows.Length -and $rows[$i]) {
            if ($rows[$i][0]) { $name = [string]$rows[$i][0] }
            if ($rows[$i][1]) { $addr = [string]$rows[$i][1] }
        }
        $map[$sid] = [PSCustomObject]@{ Name = $name; Address = $addr }
    }
    return $map
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

    # ---- enrich with normalized idle time + RDP client name / IP (WTS API) ----
    if ($sessions -and $sessions.Count -gt 0) {

        # Normalize idle time once, for both quser and qwinsta results.
        foreach ($s in $sessions) {
            $raw  = [string]$s.Idle
            $mins = ConvertTo-IdleMinutes -Value $raw
            Add-Member -InputObject $s -NotePropertyName IdleRaw     -NotePropertyValue $raw                        -Force
            Add-Member -InputObject $s -NotePropertyName IdleMinutes -NotePropertyValue $mins                       -Force
            Add-Member -InputObject $s -NotePropertyName Idle        -NotePropertyValue (Format-IdleDuration $mins) -Force
        }

        $ids = @($sessions | ForEach-Object { $_.SessionId })
        try { $clientMap = Get-RdpClientInfo -Server $Server -SessionIds $ids }
        catch { $clientMap = @{} }

        foreach ($s in $sessions) {
            $info = $null
            if ($clientMap.ContainsKey([int]$s.SessionId)) {
                $info = $clientMap[[int]$s.SessionId]
            }
            $name = if ($info -and $info.Name)    { $info.Name }    else { "" }
            $addr = if ($info -and $info.Address) { $info.Address } else { "" }

            $display = if ($name) { $name } else { "—" }

            Add-Member -InputObject $s -NotePropertyName ClientName    -NotePropertyValue $name    -Force
            Add-Member -InputObject $s -NotePropertyName ClientAddress -NotePropertyValue $addr    -Force
            Add-Member -InputObject $s -NotePropertyName ClientDisplay -NotePropertyValue $display -Force
        }
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
        'Format-HostIp',
        'ConvertTo-IdleMinutes',
        'Format-IdleDuration',
        'Resolve-IfIP',
        'Get-PingTtl',
        'Get-NetworkThroughput',
        'Parse-QuserOutput',
        'Initialize-WtsHelper',
        'Get-RdpClientInfo',
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
    $txtHostIp.Text     = "—"
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

    $btnRdpConnect.IsEnabled     = $false
    $btnRemoteServices.IsEnabled = $false
    $btnSmbCShare.IsEnabled      = $false
    $txtActionsHint.Text = "Check a server first."

    $txtPortResult.Text = ""
    $txtPortResult.FontWeight = 'Normal'
    $txtPortResult.Foreground = [System.Windows.Media.Brushes]::LightGray

    $script:SharedState.ServerName     = $null
    $script:SharedState.UserData       = @()
    $script:SharedState.NonWindowsHint = $false
    $script:SharedState.LastTtl        = $null

    $script:SortColumn    = $null
    $script:SortAscending = $true
    Update-SortIndicators

    $cmbStateFilter.SelectedIndex = 0
    $txtSearchUser.Text = ""
}

# ===========================================================================
# Sort helpers
# ===========================================================================
function Update-SortIndicators {
    $cols = @{
        'User'      = $hdrUser
        'SessionId' = $hdrSession
        'State'     = $hdrState
        'Client'    = $hdrClient
        'Idle'      = $hdrIdle
        'LogonTime' = $hdrLogon
    }
    $labels = @{
        'User'      = 'USER'
        'SessionId' = 'SESSION'
        'State'     = 'STATE'
        'Client'    = 'CLIENT'
        'Idle'      = 'IDLE'
        'LogonTime' = 'LOGON TIME'
    }
    foreach ($k in $cols.Keys) {
        $btn = $cols[$k]
        if (-not $btn) { continue }
        if ($script:SortColumn -eq $k) {
            $arrow = if ($script:SortAscending) { ' ▲' } else { ' ▼' }
            $btn.Content = $labels[$k] + $arrow
            $btn.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString('#1D4ED8')
        } else {
            $btn.Content = $labels[$k]
            $btn.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString('#4A5568')
        }
    }
}

function Invoke-SortByColumn {
    param([string]$Column)
    if (-not $Column) { return }
    if ($script:SortColumn -eq $Column) {
        $script:SortAscending = -not $script:SortAscending
    } else {
        $script:SortColumn    = $Column
        $script:SortAscending = $true
    }
    Update-SortIndicators

    $filter = if ($cmbStateFilter.SelectedItem) { $cmbStateFilter.SelectedItem.Content } else { "All sessions" }
    $search = if ($txtSearchUser) { $txtSearchUser.Text } else { "" }
    Render-Sessions -Filter $filter -Search $search `
                    -SortColumn $script:SortColumn -SortAscending $script:SortAscending
}

# ===========================================================================
# Render sessions
# ===========================================================================
function Render-Sessions {
    param(
        [string]$Filter = "All",
        [string]$Search = "",
        [string]$SortColumn = $null,
        [bool]$SortAscending = $true
    )

    $userData = $script:SharedState.UserData

    if (-not $userData -or @($userData).Count -eq 0) {
        $lstSessions.ItemsSource = @()
        $txtSelInfo.Text = "No remote (RDP) sessions currently connected."
        $btnDisconnect.IsEnabled = $false
        return
    }

    $all = $userData

    $filtered = switch ($Filter) {
        "Active only"       { $all | Where-Object { $_.StateRaw -ieq 'Active' } }
        "Disconnected only" { $all | Where-Object { $_.StateRaw -ieq 'Disc' -or $_.State -ieq 'Disconnected' } }
        default             { $all }
    }

    $needle = if ($Search) { $Search.Trim() } else { "" }
    if ($needle) {
        $filtered = @($filtered) | Where-Object {
            $_.User -and
            ($_.User.ToString().IndexOf($needle, [System.StringComparison]::OrdinalIgnoreCase) -ge 0)
        }
    }

    if (-not $filtered -or @($filtered).Count -eq 0) {
        $lstSessions.ItemsSource = @()
        if ($needle) {
            $txtSelInfo.Text = "No sessions match '$needle' (filter: $Filter)."
        } else {
            $txtSelInfo.Text = "No sessions match the current filter ($Filter)."
        }
        $btnDisconnect.IsEnabled = $false
        return
    }

    if ($SortColumn) {
        if ($SortColumn -eq 'Idle') {
            # Numeric sort on minutes; unknown idle ("none", "-") always sinks.
            $dir = if ($SortAscending) { 1 } else { -1 }
            $sorted = $filtered | Sort-Object -Property `
                @{ Expression = { $null -eq $_.IdleMinutes } }, `
                @{ Expression = { if ($null -eq $_.IdleMinutes) { 0 } else { $dir * [double]$_.IdleMinutes } } }
        } else {
            $sorted = $filtered | Sort-Object -Property $SortColumn -Descending:(-not $SortAscending)
        }
    } else {
        $sorted = $filtered | Sort-Object @{Expression={ $_.State -ieq 'Disconnected' }}, User
    }

    $rows = @()
    foreach ($s in $sorted) {
        $clientStr = [string]$s.ClientDisplay
        if ([string]::IsNullOrWhiteSpace($clientStr)) { $clientStr = "—" }

        $color = if ($s.State -ieq 'Disconnected') { "#9E9E9E" } else { "#2E7D32" }

        $rows += [PSCustomObject]@{
            User          = [string]$s.User
            SessionId     = $s.SessionId
            State         = [string]$s.State
            Client        = $clientStr
            ClientAddress = [string]$s.ClientAddress
            Idle          = [string]$s.Idle
            LogonTime     = [string]$s.LogonTime
            Color         = $color
            Session       = $s
        }
    }

    $lstSessions.ItemsSource = $rows

    $suffix = ""
    if ($needle) { $suffix = "  |  search: '$needle'" }
    $sortSuffix = if ($SortColumn) {
        $dir = if ($SortAscending) { '↑' } else { '↓' }
        "  |  sort: $SortColumn $dir"
    } else { "" }
    $txtSelInfo.Text = ("Showing {0} of {1} session(s){2}{3}. Ctrl/Shift-click to select multiple." -f `
                        @($rows).Count, @($all).Count, $suffix, $sortSuffix)
    $btnDisconnect.IsEnabled = $false
}

# ---------------------------------------------------------------------------
# Pre-built UI-thread delegates
# ---------------------------------------------------------------------------
$script:RefreshSessionsAction = [action]{
    if ($script:SharedState.UserData -and @($script:SharedState.UserData).Count -gt 0) {
        $search = if ($txtSearchUser) { $txtSearchUser.Text } else { "" }
        $filter = if ($cmbStateFilter.SelectedItem) { $cmbStateFilter.SelectedItem.Content } else { "All sessions" }
        Render-Sessions -Filter $filter -Search $search `
                        -SortColumn $script:SortColumn -SortAscending $script:SortAscending
    } else {
        $lstSessions.ItemsSource = @()
        $txtSelInfo.Text = "No remote (RDP) sessions currently connected."
        $btnDisconnect.IsEnabled = $false
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
            $Window.FindName('btnRdpConnect').IsEnabled     = $true
            $Window.FindName('btnRemoteServices').IsEnabled = $true
            $Window.FindName('btnSmbCShare').IsEnabled      = $true
            $Window.FindName('txtActionsHint').Text         = "Target: $ServerName"
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

        try {
            $ipList = @()
            try {
                $entry  = [System.Net.Dns]::GetHostEntry($ServerName)
                $ipList = @($entry.AddressList | ForEach-Object { $_.IPAddressToString })
            } catch { }
            $hostIpText = Format-HostIp -HostName $ServerName -IpAddresses $ipList
            Update-UI { $Window.FindName('txtHostIp').Text = $hostIpText }
        } catch { }

        Update-UI {
            $Window.FindName('txtStatus').Text =
                "⚠ '$ServerName' appears to be a non-Windows host ($ttlText). Resource metrics skipped."
            $Window.FindName('txtFooter').Text =
                "Last check: $timeStr  |  Target: $ServerName  |  v2.3.0  |  ⚠ $ttlText (non-Windows?)"
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

    # ---- Hostname / IP line ----
    try {
        $resolvedHost = $ServerName
        $ipList       = @()
        try {
            $entry = [System.Net.Dns]::GetHostEntry($ServerName)
            if ($entry.HostName) { $resolvedHost = $entry.HostName.Split('.')[0] }
            $ipList = @($entry.AddressList | ForEach-Object { $_.IPAddressToString })
        } catch {
            try {
                $ping = & ping -4 -n 1 -w 1000 $ServerName 2>$null
                if ($ping -match '\[([\d\.]+)\]') { $ipList = @($matches[1]) }
            } catch { }
        }

        $hostIpText = Format-HostIp -HostName $resolvedHost -IpAddresses $ipList
        Update-UI { $Window.FindName('txtHostIp').Text = $hostIpText }
    } catch {
        $msg = "Host/IP query failed: $($_.Exception.Message)"
        Update-UI { $Window.FindName('txtHostIp').Text = $msg }
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
        $Window.FindName('txtFooter').Text = "Last check: $timeStr  |  Target: $ServerName  |  v2.3.0  |  $ttlText"
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
        $Window.FindName('txtFooter').Text = "RDP session list refreshed: $timeStr  |  Target: $ServerName  |  v2.3.0"
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
# Background script: Disconnect sessions (supports multiple)
# ===========================================================================
$script:DisconnectScript = @'
param($ServerName, $Targets)

function Update-UI {
    param([scriptblock]$Action)
    $Window.Dispatcher.Invoke($Action, [System.Windows.Threading.DispatcherPriority]::Background)
}

$ok = 0; $fail = 0; $failMsgs = @()
foreach ($t in $Targets) {
    try {
        $output = & logoff $t.Id /server:$ServerName 2>&1
        if ($LASTEXITCODE -eq 0) { $ok++ }
        else { $fail++; $failMsgs += "$($t.User) (session $($t.Id)): $output" }
    } catch {
        $fail++
        $failMsgs += "$($t.User) (session $($t.Id)): $($_.Exception.Message)"
    }
}

$timeStr = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'

Update-UI {
    $msg = if ($fail -eq 0) {
        "Disconnected $ok session(s) from $ServerName."
    } elseif ($ok -eq 0) {
        "Failed to disconnect $fail session(s): $($failMsgs -join '; ')"
    } else {
        "Disconnected $ok session(s); $fail failed: $($failMsgs -join '; ')"
    }
    $Window.FindName('txtStatus').Text = $msg
    $Window.FindName('txtFooter').Text = "Disconnect at $timeStr  |  Target: $ServerName  |  v2.3.0"
}

Start-Sleep -Milliseconds 500
Update-UI { $Window.FindName('btnDisconnect').IsEnabled = $true }
try {
    $Window.Dispatcher.Invoke($ReloadAction, [System.Windows.Threading.DispatcherPriority]::Background)
} catch { }
'@

# ===========================================================================
# Background script: Port check
# ===========================================================================
$script:PortCheckScript = @'
param($ServerName, $Port)

function Update-UI {
    param([scriptblock]$Action)
    $Window.Dispatcher.Invoke($Action, [System.Windows.Threading.DispatcherPriority]::Background)
}

try {
    $result = Test-NetConnection -ComputerName $ServerName -Port $Port `
              -WarningAction SilentlyContinue -ErrorAction Stop

    $reachable = $false
    if ($result -and $result.PSObject.Properties['TcpTestSucceeded']) {
        $reachable = [bool]$result.TcpTestSucceeded
    }

    Update-UI {
        $tb = $Window.FindName('txtPortResult')
        $tb.FontWeight = 'Bold'
        if ($reachable) {
            $tb.Text = "Port test successful."
            $tb.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString('#4ADE80')
        } else {
            $tb.Text = "Can't reach this port."
            $tb.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString('#F87171')
        }
    }
}
catch {
    Update-UI {
        $tb = $Window.FindName('txtPortResult')
        $tb.Text = "Unreachable"
        $tb.FontWeight = 'Bold'
        $tb.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString('#F87171')
    }
}
finally {
    Update-UI { $Window.FindName('btnTryPort').IsEnabled = $true }
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
# Confirmation dialog (single or multi session)
# ===========================================================================
function Show-DisconnectConfirmation {
    param(
        [string]$Server,
        [PSCustomObject[]]$Sessions
    )

    $escServer = [System.Security.SecurityElement]::Escape($Server)
    $count     = @($Sessions).Count
    if ($count -eq 0) { return $false }

    if ($count -eq 1) {
        $s          = $Sessions[0]
        $escUser    = [System.Security.SecurityElement]::Escape($s.User)
        $escState   = [System.Security.SecurityElement]::Escape($s.State)
        $escLogon   = [System.Security.SecurityElement]::Escape([string]$s.LogonTime)
        $escSession = [System.Security.SecurityElement]::Escape("ID $($s.SessionId)")
        $escClient  = [System.Security.SecurityElement]::Escape([string]$s.ClientDisplay)
        $stateColor = if ($s.State -ieq 'Disconnected') { "#9E9E9E" } else { "#2E7D32" }
        $headerText = "Disconnect this user?"
        $confirmLabel = "Disconnect"
        $winHeight  = 510
        $winWidth   = 640

        $userBlock = @"
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

                    <TextBlock Grid.Row="2" Grid.Column="0" Text="Client:"
                               Foreground="#8A94A6" FontSize="13" Margin="0,4"/>
                    <TextBlock Grid.Row="2" Grid.Column="1" Text="$escClient"
                               Foreground="#0F766E" FontSize="13" FontWeight="Bold" Margin="0,4"
                               TextWrapping="Wrap"/>

                    <TextBlock Grid.Row="3" Grid.Column="0" Text="State:"
                               Foreground="#8A94A6" FontSize="13" Margin="0,4"/>
                    <TextBlock Grid.Row="3" Grid.Column="1" Text="$escState"
                               Foreground="$stateColor" FontSize="13" FontWeight="Bold" Margin="0,4"
                               TextWrapping="Wrap"/>

                    <TextBlock Grid.Row="4" Grid.Column="0" Text="Logon:"
                               Foreground="#8A94A6" FontSize="13" Margin="0,4"/>
                    <TextBlock Grid.Row="4" Grid.Column="1" Text="$escLogon"
                               Foreground="#1F2933" FontSize="13" Margin="0,4"
                               TextWrapping="Wrap"/>
                </Grid>
"@
    } else {
        $headerText   = "Disconnect $count users?"
        $confirmLabel = "Disconnect $count"
        $winHeight    = 560
        $winWidth     = 680

        $sb = New-Object System.Text.StringBuilder
        [void]$sb.AppendLine('<TextBlock Text="SERVER" Foreground="#8A94A6" FontSize="11" FontWeight="Bold" Margin="0,0,0,4"/>')
        [void]$sb.AppendLine("<TextBlock Text=`"$escServer`" Foreground=`"#2563EB`" FontSize=`"14`" FontWeight=`"Bold`" Margin=`"0,0,0,14`" TextWrapping=`"Wrap`"/>")
        [void]$sb.AppendLine("<TextBlock Text=`"SESSIONS TO DISCONNECT ($count)`" Foreground=`"#8A94A6`" FontSize=`"11`" FontWeight=`"Bold`" Margin=`"0,0,0,6`"/>")
        [void]$sb.AppendLine('<ScrollViewer VerticalScrollBarVisibility="Auto" MaxHeight="220">')
        [void]$sb.AppendLine('<StackPanel>')
        foreach ($s in $Sessions) {
            $u   = [System.Security.SecurityElement]::Escape([string]$s.User)
            $sid = [System.Security.SecurityElement]::Escape("$($s.SessionId)")
            $st  = [System.Security.SecurityElement]::Escape([string]$s.State)
            [void]$sb.AppendLine("<TextBlock Foreground=`"#C2410C`" FontSize=`"14`" FontWeight=`"Bold`" Margin=`"0,3`" TextWrapping=`"Wrap`">$u <Run Foreground=`"#8A94A6`" FontWeight=`"Normal`">(session $sid — $st)</Run></TextBlock>")
        }
        [void]$sb.AppendLine('</StackPanel>')
        [void]$sb.AppendLine('</ScrollViewer>')

        $userBlock = $sb.ToString()
    }

    $confirmXaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Confirm Disconnect" Height="$winHeight" Width="$winWidth"
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

        <TextBlock Grid.Row="0" Text="$headerText"
                   Foreground="#B45309" FontSize="20" FontWeight="Bold"
                   TextAlignment="Center" HorizontalAlignment="Center"/>

        <TextBlock Grid.Row="1" Margin="0,10,0,18" TextWrapping="Wrap"
                   Foreground="#616161" FontSize="12"
                   TextAlignment="Center" HorizontalAlignment="Center"
                   Text="The selected user(s) will be forcibly logged off from the remote server. Any unsaved work may be lost. This action cannot be undone."/>

        <Border Grid.Row="2" Background="White" BorderBrush="#E2E6EC"
                BorderThickness="1" CornerRadius="10" Padding="18">
            <StackPanel>
$userBlock
            </StackPanel>
        </Border>

        <StackPanel Grid.Row="3" Orientation="Horizontal"
                    HorizontalAlignment="Right" Margin="0,18,0,0">
            <Button Name="btnCancel" Content="Cancel" Width="120" Height="36"
                    Margin="0,0,10,0" Background="#E2E6EC" Foreground="#334155"
                    BorderThickness="0" Cursor="Hand" FontSize="13"/>
            <Button Name="btnConfirm" Content="$confirmLabel" Width="150" Height="36"
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
# Disconnect-Session(s): dispatch background task
# ===========================================================================
function Disconnect-Session {
    param(
        [string]$Server,
        [PSCustomObject[]]$Sessions
    )

    $Server = Resolve-IfIP -Server $Server

    $targets = @()
    foreach ($s in $Sessions) {
        if ($null -eq $s.SessionId -or "$($s.SessionId)" -eq "-") { continue }
        $targets += [PSCustomObject]@{ Id = [int]$s.SessionId; User = [string]$s.User }
    }

    if ($targets.Count -eq 0) {
        [System.Windows.MessageBox]::Show(
            "No valid session IDs in the selection. Cannot logoff.",
            "Disconnect failed", 'OK', 'Warning') | Out-Null
        return
    }

    $btnDisconnect.IsEnabled = $false

    Start-BackgroundTask -ScriptText $script:DisconnectScript `
        -Arguments @($Server, $targets) `
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
    $txtPort.Text = "443"
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
        $filter = if ($cmbStateFilter.SelectedItem) { $cmbStateFilter.SelectedItem.Content } else { "All sessions" }
        $search = if ($txtSearchUser) { $txtSearchUser.Text } else { "" }
        Render-Sessions -Filter $filter -Search $search `
                        -SortColumn $script:SortColumn -SortAscending $script:SortAscending
    }
})

$txtSearchUser.Add_TextChanged({
    if ($script:SharedState.UserData -and @($script:SharedState.UserData).Count -gt 0) {
        $filter = if ($cmbStateFilter.SelectedItem) { $cmbStateFilter.SelectedItem.Content } else { "All sessions" }
        Render-Sessions -Filter $filter -Search $txtSearchUser.Text `
                        -SortColumn $script:SortColumn -SortAscending $script:SortAscending
    }
})

# ---- Header click handlers (sorting) ----
$hdrUser.Add_Click({    Invoke-SortByColumn -Column 'User' })
$hdrSession.Add_Click({ Invoke-SortByColumn -Column 'SessionId' })
$hdrState.Add_Click({   Invoke-SortByColumn -Column 'State' })
$hdrClient.Add_Click({  Invoke-SortByColumn -Column 'Client' })
$hdrIdle.Add_Click({    Invoke-SortByColumn -Column 'Idle' })
$hdrLogon.Add_Click({   Invoke-SortByColumn -Column 'LogonTime' })

# ---- Multi-select aware selection handler ----
$lstSessions.Add_SelectionChanged({
    $sel = @($lstSessions.SelectedItems)
    if ($sel.Count -eq 0) {
        $txtSelInfo.Text = "No session selected."
        $btnDisconnect.IsEnabled = $false
    } elseif ($sel.Count -eq 1) {
        $s = $sel[0].Session
        $client = if ($s.ClientDisplay) { $s.ClientDisplay } else { "—" }
        $txtSelInfo.Text = ("Selected: {0}  |  Session {1}  |  {2}  |  Client: {3}" -f `
                            $s.User, $s.SessionId, $s.State, $client)
        $btnDisconnect.IsEnabled = $true
    } else {
        $users = @($sel | ForEach-Object { $_.Session.User })
        $preview = ($users | Select-Object -First 5) -join ", "
        if ($users.Count -gt 5) { $preview += ", ..." }
        $txtSelInfo.Text = ("{0} sessions selected: {1}" -f $sel.Count, $preview)
        $btnDisconnect.IsEnabled = $true
    }
})

$btnDisconnect.Add_Click({
    $selected = @($lstSessions.SelectedItems)
    if ($selected.Count -eq 0) {
        $txtStatus.Text = "Select at least one session to disconnect."
        return
    }

    $sessions = @($selected | ForEach-Object { $_.Session })
    $server   = $script:SharedState.ServerName

    $confirmed = Show-DisconnectConfirmation -Server $server -Sessions $sessions
    if (-not $confirmed) {
        $txtStatus.Text = "Disconnect cancelled."
        return
    }

    Disconnect-Session -Server $server -Sessions $sessions
})

# ---- Quick Actions handlers ----
$btnRdpConnect.Add_Click({
    $server = $script:SharedState.ServerName
    if (-not $server) {
        $txtStatus.Text = "Check a server first."
        return
    }
    try {
        Start-Process -FilePath "mstsc.exe" -ArgumentList "/v:$server"
        $txtStatus.Text = "Launched RDP client for '$server'."
    } catch {
        $txtStatus.Text = "RDP launch failed: $($_.Exception.Message)"
    }
})

$btnRemoteServices.Add_Click({
    $server = $script:SharedState.ServerName
    if (-not $server) {
        $txtStatus.Text = "Check a server first."
        return
    }
    try {
        Start-Process -FilePath "mmc.exe" -ArgumentList "services.msc /computer=$server"
        $txtStatus.Text = "Opening services.msc against '$server'..."
    } catch {
        $txtStatus.Text = "Services launch failed: $($_.Exception.Message)"
    }
})

$btnSmbCShare.Add_Click({
    $server = $script:SharedState.ServerName
    if (-not $server) {
        $txtStatus.Text = "Check a server first."
        return
    }
    $unc = "\\$server\c$"
    try {
        Start-Process -FilePath "explorer.exe" -ArgumentList $unc
        $txtStatus.Text = "Opening $unc in File Explorer..."
    } catch {
        $txtStatus.Text = "SMB open failed: $($_.Exception.Message)"
    }
})

# ---- Port Check handler ----
$btnTryPort.Add_Click({
    $srv = $txtServer.Text.Trim()
    if ([string]::IsNullOrWhiteSpace($srv)) {
        $txtStatus.Text = "Enter a server name first."
        return
    }

    $portNum = 0
    if (-not [int]::TryParse($txtPort.Text.Trim(), [ref]$portNum) -or
        $portNum -lt 1 -or $portNum -gt 65535) {
        $txtStatus.Text = "Enter a valid port number (1-65535)."
        $txtPortResult.Text = ""
        $txtPortResult.FontWeight = 'Normal'
        return
    }

    $resolved = Resolve-IfIP -Server $srv

    $btnTryPort.IsEnabled = $false
    $txtPortResult.Text = "Checking..."
    $txtPortResult.FontWeight = 'Normal'
    $txtPortResult.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString('#A8B6C8')

    Start-BackgroundTask -ScriptText $script:PortCheckScript `
        -Arguments @($resolved, $portNum) `
        -Globals @{
            Window = $window
        } | Out-Null
})

$txtServer.Add_KeyDown({
    if ($_.Key -eq [System.Windows.Input.Key]::Enter) {
        $btnCheck.RaiseEvent((New-Object System.Windows.RoutedEventArgs([System.Windows.Controls.Button]::ClickEvent)))
    }
})

$txtPort.Add_KeyDown({
    if ($_.Key -eq [System.Windows.Input.Key]::Enter) {
        $btnTryPort.RaiseEvent((New-Object System.Windows.RoutedEventArgs([System.Windows.Controls.Button]::ClickEvent)))
    }
})

# ===========================================================================
# Force-terminate host on window close (ps2exe cleanup)
# ===========================================================================
$window.Add_Closed({
    try {
        [System.Diagnostics.Process]::GetCurrentProcess().Kill()
    } catch { }
})

$window.ShowDialog() | Out-Null

try {
    [System.Diagnostics.Process]::GetCurrentProcess().Kill()
} catch { }