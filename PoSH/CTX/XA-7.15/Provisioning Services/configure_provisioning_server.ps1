Write-Verbose "Setting Arguments" -Verbose
$StartDTM = (Get-Date)

$Product = "Configure Citrix Provisioning Server"
$LogPS = "${env:SystemRoot}" + "\Temp\$Product PS Wrapper.log"
$PackageName = "ConfigWizard"
$InstallerType = "exe"
$UnattendedArgs = '/A'
$WorkingDirectory = (Split-Path $MyInvocation.MyCommand.path -Parent)

$DatabaseServer = "dc.bretty.me.uk"                                                       
$DatabaseName = "bretty_pvs"
$FarmName = "bretty"
$SiteName = "Liphook"
$DefaultCollectionName = "Master Images"
$DefaultStoreName = "vDisk Store"
$DefaultStorePath = "$env:SystemDrive\vDisks"
$LicenseServer = "lic.bretty.me.uk"
$LicenseServerPort = "27000"                                                             
$FirstStreamingPort = "6910"
$LastStreamingPort = "6968"                                                                
$UserName = "bretty\administrator"
$Password = "Jp1hlwci.021978"
$FarmAdminGroupName = "bretty.me.uk/deployment/security groups/admin/pvs admins"
$MaxPasswordAge = "10"

$OU = "bretty/workers/citrix/server workloads/Master"
$Collection1 = "Windows Server 2016 x64 - Master"

Start-Transcript $LogPS

$AvailableNICs = gwmi Win32_NetworkAdapter -Filter "NetEnabled='True'"
ForEach ($Adapter in $AvailableNICs) {
    $IPv4Address = $(gwmi Win32_NetworkAdapterConfiguration -Filter "Index = '$($Adapter.Index)'").IPAddress
}

# Create Firewall Rules
netsh advfirewall firewall add rule name="Citrix PVS (Inbound,TCP)" description="Inbound rules for the TCP protocol for Citrix Provisioning Server ports" localport="389,1433,54321-54323" protocol="TCP" dir="In" action="Allow"
netsh advfirewall firewall add rule name="Citrix PVS (Inbound,UDP)" description="Inbound rules for the UDP protocol for Citrix Provisioning Server ports" localport="67,69,2071,6910-6930,6969,4011,6890-6909" protocol="UDP" dir="In" action="Allow"
netsh advfirewall firewall add rule name="Citrix PVS (Outbound,TCP)" description="Outbound rules for the TCP protocol for Citrix Provisioning Server ports" localport="389,1433,54321-54323" protocol="TCP" dir="Out" action="Allow"
netsh advfirewall firewall add rule name="Citrix PVS (Outbound,UDP)" description="Outbound rules for the UDP protocol for Citrix Provisioning Server ports" localport="67,69,2071,6910-6930,6969,4011,6890-6909" protocol="UDP" dir="Out" action="Allow"

# Create Answer File
$Text += "FarmConfiguration="              + "1"                                                                  + "`r`n"
$Text += "BootstrapFile="                  + "C:\ProgramData\Citrix\Provisioning Services\Tftpboot\ARDBP32.BIN"   + "`r`n"
$Text += "DatabaseServer="                 + $DatabaseServer                                                      + "`r`n"
$Text += "DatabaseNew="                    + $DatabaseName                                                        + "`r`n"
$Text += "FarmNew="                        + $FarmName                                                            + "`r`n"
$Text += "SiteNew="                        + $SiteName                                                            + "`r`n"
$Text += "CollectionNew="                  + $DefaultCollectionName                                               + "`r`n"
$Text += "Store="                          + $DefaultStoreName                                                    + "`r`n"
$Text += "DefaultPath="                    + $DefaultStorePath                                                    + "`r`n"
$Text += "PasswordManagementInterval="     + $MaxPasswordAge                                                      + "`r`n"
$Text += "LicenseServer="                  + $LicenseServer                                                       + "`r`n"
$Text += "LicenseServerPort="              + $LicenseServerPort                                                   + "`r`n"
$Text += "LS1="                        + "$($IPv4Address),0.0.0.0,0.0.0.0,$FirstStreamingPort"                    + "`r`n"
$Text += "StreamNetworkAdapterIP="     + $IPv4Address                                                             + "`r`n"
$Text += "UserName="                       + $UserName                                                            + "`r`n"
$Text += "UserPass="                       + $Password                                                            + "`r`n"

# Create the Config Wizard ANS file for CREATING a NEW farm
$ConfWizardANSFileCreateFarm = "c:\programdata\Citrix\Provisioning Services\ConfigWizard.ans"
Set-Content $ConfWizardANSFileCreateFarm -value ($Text) -Encoding Unicode

# Create vDisk Store Directory
new-item $DefaultStorePath -type Directory -Force

# Switch to Configuration Directory
CD "C:\Program Files\Citrix\Provisioning Services"

# Configure Provisioning Services Farm
Write-Verbose "Starting to $Product" -Verbose
(Start-Process "$PackageName.$InstallerType" $UnattendedArgs -Wait -Passthru).ExitCode

# Wait 60 Seconds
Start-Sleep -Seconds 60

Write-Verbose "Customization" -Verbose

# Add Citrix Snapins
asnp citrix*
Import-Module "C:\Program Files\Citrix\Provisioning Services Console\Citrix.PVS.SnapIn.dll"

# Create PVS Authentication Group
New-PvsAuthGroup -Name $FarmAdminGroupName
Grant-PvsAuthGroup -authGroupName $FarmAdminGroupName

# Configure PVS Farm Settings
Set-PvsFarm -AuditingEnabled -OfflineDatabaseSupportEnabled -LicenseServer $LicenseServer -LicenseServerPort $LicenseServerPort

# Disable Customer Experience Experience
Set-PvsCeipData -enabled 0

# Enable Verbose Boot Mode
Set-PvsServerBootstrap -Name "ARDBP32.bin" -ServerName $env:ComputerName -VerboseMode

# Configure PVS Local Host
$NumberOfCores = (gwmi win32_ComputerSystem).numberoflogicalprocessors
if ( $NumberOfCores -lt 8 ) { $NumberOfCores = 8 }     
Set-PvsServer -ServerName $env:ComputerName -FirstPort $FirstStreamingPort -LastPort $LastStreamingPort -ThreadsPerPort $NumberOfCores -AdMaxPasswordAge $MaxPasswordAge -AdMaxPasswordAgeEnabled -EventLoggingEnabled               

Write-Verbose "Stop logging" -Verbose
$EndDTM = (Get-Date)
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalSeconds) Seconds" -Verbose
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalMinutes) Minutes" -Verbose
Stop-Transcript