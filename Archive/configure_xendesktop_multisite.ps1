$SiteBAGName = "xdsite.bretty.me.uk"
$SiteDBName = "xendesktop_site"
$LogBAGName = "xdconfig.bretty.me.uk"
$LogDBName = "xendesktop_config"
$MonitorBAGName = "xdmonitor.bretty.me.uk"
$MonitorDBName = "xendesktop_monitor"

$cs="Server=$SiteBAGName;Initial Catalog=$SiteDBName;Integrated Security=True;MultiSubnetFailover=True"
Write-Host $cs
$csLogging= "Server=$LogBAGName;Initial Catalog=$LogDBName;Integrated Security=True;MultiSubnetFailover=True"
Write-Host $csLogging
$csMonitoring = "Server=$MonitorBAGName;Initial Catalog=$MonitorDBName;Integrated Security=True;MultiSubnetFailover=True"
Write-Host $csMonitoring



#Add Snapin
Add-PSSnapin Citrix*

#Disable logging
set-logsite -state "Disabled"

#Clear connections
Set-AnalyticsDBConnection -DBConnection $null -force             #  7.6 and newer
Set-AppLibDBConnection -DBConnection $null -force                  # 7.8 and newer
Set-OrchDBConnection -DBConnection $null -force                    #  7.11 and newer
Set-TrustDBConnection -DBConnection $null -force                    #  7.11 and newer
Set-HypDBConnection -DBConnection $null -force
Set-ProvDBConnection -DBConnection $null -force
Set-BrokerDBConnection -DBConnection $null -force
Set-EnvTestDBConnection -DBConnection $null -force
Set-SfDBConnection -DBConnection $null -force
Set-MonitorDBConnection -DataStore Monitor -DBConnection $null -force
Set-MonitorDBConnection -DBConnection $null -force
Set-LogDBConnection -DataStore Logging -DBConnection $null -force
Set-LogDBConnection -DBConnection $null -force
Set-ConfigDBConnection -DBConnection $null  -force
Set-AcctDBConnection -DBConnection $null -force
Set-AdminDBConnection -DBConnection $null -force

#Set Multisubnet connections
Set-AdminDBConnection -DBConnection $cs
Set-ConfigDBConnection -DBConnection $cs
Set-AcctDBConnection -DBConnection $cs
Set-AnalyticsDBConnection -DBConnection $cs               # 7.6 and newer
Set-HypDBConnection -DBConnection $cs             
Set-ProvDBConnection -DBConnection $cs
Set-AppLibDBConnection –DBConnection $cs                 #  7.8 and newer
Set-OrchDBConnection –DBConnection $cs                    # 7.11 and newer
Set-TrustDBConnection –DBConnection $cs                  #  7.11 and newer
Set-PvsVmDBConnection -DBConnection $cs               # PBO: Will fail, maybe needed by older DDCs
Set-BrokerDBConnection -DBConnection $cs
Set-EnvTestDBConnection -DBConnection $cs
Set-SfDBConnection -DBConnection $cs
Set-LogDBConnection -DBConnection $cs
Set-LogDBConnection -DataStore Logging -DBConnection $csLogging
Set-MonitorDBConnection -DBConnection $cs
Set-MonitorDBConnection -DataStore Monitor -DBConnection $csMonitoring

#Enable logging
set-logsite -state "Enabled"

#Get connection strings
Write-Host "Configured connection strings for this controller"
Get-AdminDBConnection
Get-AcctDBConnection
Get-AnalyticsDBConnection   # 7.6 and newer
Get-HypDBConnection         
Get-ProvDBConnection
Get-AppLibDBConnection  #  7.8 and newer
Get-OrchDBConnection    # 7.11 and newer
Get-TrustDBConnection   #  7.11 and newer
Get-BrokerDBConnection
Get-EnvTestDBConnection
Get-SfDBConnection
Get-LogDBConnection
Get-LogDBConnection -DataStore Logging
Get-MonitorDBConnection
Get-MonitorDBConnection -DataStore Monitor