Write-Verbose "Setting Arguments" -Verbose
$StartDTM = (Get-Date)

$MyConfigFileloc = ("Settings.xml")
[xml]$MyConfigFile = (Get-Content $MyConfigFileLoc)

$Vendor = "Citrix"
$Product = "XenDesktop"
$Version = $MyConfigFile.Post.Version
$LogPS = "${env:SystemRoot}" + "\Temp\Configure $Vendor $Product $Version Site PS Wrapper.log"

$DatabaseServer = "dc.bretty.me.uk"
$DatabaseName_Site = "bretty-site"
$DatabaseName_Logging = "bretty-logging"
$DatabaseName_Monitor = "bretty-monitor"
$DatabaseUser = "bretty\administrator"
$DatabasePassword = "Jp1hlwci.021978"
$brettySite = "bretty"
$FullAdminGroup = "bretty\xd admins"
$LicenseServer = "lic.bretty.me.uk"
$LicenseServer_LicensingModel = "UserDevice"
$LicenseServer_ProductCode = "XDT"
$LicenseServer_ProductEdition = "PLT"
$LicenseServer_Port = "27000"
$LicenseServer_ProductVersion = "$Version"
$LicenseServer_AddressType = "WSL"

$DatabasePassword = $DatabasePassword | ConvertTo-SecureString -asPlainText -Force
$Database_CredObject = New-Object System.Management.Automation.PSCredential($DatabaseUser,$DatabasePassword)

Start-Transcript $LogPS

Add-PSSnapin Citrix.*

asnp citrix*
New-XDSite -LoggingDatabaseName "xendesktop_config" -LoggingDatabaseServer "xdconfig.bretty.me.uk" -MonitorDatabaseName "xendesktop_monitor" -MonitorDatabaseServer "xdmonitor.bretty.me.uk" -SiteDatabaseName "xendesktop_site" -SiteDatabaseServer "xdsite.bretty.me.uk" -SiteName "bretty_xd"

New-XDSite -LoggingDatabaseName "xendesktop_config" -LoggingDatabaseServer "xdconfig.bretty.me.uk" -MonitorDatabaseName "xendesktop_monitor"
-MonitorDatabaseServer <String> -SiteDatabaseName <String> -SiteDatabaseServer <String> -SiteName <String>
[-LoggingDatabaseMirrorServer <String>] [-MonitorDatabaseMirrorServer <String>] [-SiteDatabaseMirrorServer
<String>] [-AdminAddress <String>] [<CommonParameters>]

New-XDDatabase -AdminAddress $env:COMPUTERNAME -SiteName $brettySite -DataStore Site -DatabaseServer $DatabaseServer -DatabaseName $DatabaseName_Site -DatabaseCredentials $Database_CredObject 
New-XDDatabase -AdminAddress $env:COMPUTERNAME -SiteName $brettySite -DataStore Logging -DatabaseServer $DatabaseServer -DatabaseName $DatabaseName_Logging -DatabaseCredentials $Database_CredObject 
New-XDDatabase -AdminAddress $env:COMPUTERNAME -SiteName $brettySite -DataStore Monitor -DatabaseServer $DatabaseServer -DatabaseName $DatabaseName_Monitor -DatabaseCredentials $Database_CredObject

New-XDSite -AdminAddress $env:COMPUTERNAME -SiteName $brettySite -DatabaseServer $DatabaseServer -LoggingDatabaseName $DatabaseName_Logging -MonitorDatabaseName $DatabaseName_Monitor -SiteDatabaseName $DatabaseName_Site

Set-XDLicensing -AdminAddress $env:COMPUTERNAME -LicenseServerAddress $LicenseServer -LicenseServerPort $LicenseServer_Port
Set-ConfigSite  -AdminAddress $env:COMPUTERNAME -LicensingModel $LicenseServer_LicensingModel -ProductCode $LicenseServer_ProductCode -ProductEdition $LicenseServer_ProductEdition 
Set-ConfigSiteMetadata -AdminAddress $env:COMPUTERNAME -Name 'CertificateHash' -Value $(Get-LicCertificate -AdminAddress "https://$LicenseServer").CertHash

Set-BrokerSite -TrustRequestsSentToTheXmlServicePort $true

Write-Verbose "Stop logging" -Verbose
$EndDTM = (Get-Date)
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalSeconds) Seconds" -Verbose
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalMinutes) Minutes" -Verbose
Stop-Transcript
