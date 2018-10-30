# Determine where to do the logging
$logPS = "C:\Windows\Temp\disable_ipv6.log"

Write-Verbose "Setting Arguments" -Verbose
$StartDTM = (Get-Date)

Start-Transcript $LogPS

# Networking Parameters
#==================
$VLANName = "vlan_100"

# Configure Networking (Disable IPv6 and Rename Adapter
#==================
$Adapter = Get-NetAdapter
$NICName = $Adapter.Name
Disable-NetAdapterBinding -InterfaceAlias $NICName -ComponentID ms_tcpip6
New-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\services\TCPIP6\Parameters -Name DisabledComponents -PropertyType DWord -Value 0xffffffff
rename-netadapter -name $NICName -newname $VLANName

Write-Verbose "Stop logging" -Verbose
$EndDTM = (Get-Date)
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalSeconds) Seconds" -Verbose
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalMinutes) Minutes" -Verbose
Stop-Transcript
