Write-Verbose "Setting Arguments" -Verbose
$StartDTM = (Get-Date)

$Vendor = "Citrix"
$Product = "Workspace Environment Management Configuration"
$Version = "4.5"
$LogPS = "${env:SystemRoot}" + "\Temp\Customize $Vendor $Product $Version Site PS Wrapper.log"

$WEMServer = "wem"

Start-Transcript $LogPS

# Start a remote PS Session
Write-Verbose "Start a remote session" -Verbose
Enter-PSSession -ComputerName $WEMServer

# Create Local Variables in Remote Session
$SQLUserName = "cwem"
$SQLPassword = "Jp1hlwci.021978"
$WEMUserName = "bretty\svc-ctx-wem"
$WEMPassword = "Jp1hlwci.021978"
$DBname = "cwem"
$SQLDBLocation = "C:\Program Files\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\DATA\"
$SQLServer = "dc"
$DefaultAdminGroup = "BRETTY\wem admins"
$LicenseServerName = "lic.bretty.me.uk"

# Import CWEM SDK
Write-Verbose "Import CWEM Module" -Verbose
Import-Module "C:\Program Files (x86)\Norskale\Norskale Infrastructure Services\Citrix.Wem.InfrastructureServiceConfiguration.dll" -Verbose

# Set up SQL Server Credentials
Write-Verbose "Preparing SQL Server credentials" -Verbose
$passwd = ConvertTo-SecureString $SQLPassword -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential($SQLUserName, $passwd)

# Set up WEM Server Credentials
Write-Verbose "Preparing WEM Server credentials" -Verbose
$wempasswd = ConvertTo-SecureString $WEMPassword -AsPlainText -Force
$wemcred = New-Object System.Management.Automation.PSCredential($wemUserName, $wempasswd)

# Create Database 
Write-Verbose "Create New Database using Windows Authenticaion" -Verbose
New-WemDatabase -DatabaseServerInstance $SQLServer -DatabaseName $DBname -DataFilePath($SQLDBLocation+$DBname+"_Data.mdf") -LogFilePath($SQLDBLocation+$DBname+"_Log.ldf") -DefaultAdministratorsGroup $DefaultAdminGroup -SqlServerCredential $cred -PSDebugMode Enable 
Write-Verbose "Configure CWEM with new Database" -Verbose
Set-WemInfrastructureServiceConfiguration -DatabaseServerInstance $SQLServer -DatabaseName $DBname -LicenseServerName $LicenseServerName -InfrastructureServiceAccountCredential $wemcred

Write-Verbose "Stop logging" -Verbose
$EndDTM = (Get-Date)
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalSeconds) Seconds" -Verbose
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalMinutes) Minutes" -Verbose
Stop-Transcript
