# Determine where to do the logging
$logPS = "C:\Windows\Temp\enable_sql_ha.log"

Write-Verbose "Setting Arguments" -Verbose
$StartDTM = (Get-Date)

Start-Transcript $LogPS

# Configure SQL HA
#==================

$ComputerName = Get-childitem -path env: | where-object {$_.name -like "ComputerName"} | select-object -expandproperty value
$sqlserviceuserNoDomain = "svc-ms-sql"

Start-process -FilePath setspn -ArgumentList "-A MSSQLSvc/$($ComputerName).bretty.me.uk:1433 $($sqlserviceuserNoDomain) " -NoNewWindow -Wait -PassThru
Start-process -FilePath setspn -ArgumentList "-A MSSQLSvc/$($ComputerName).bretty.me.uk $($sqlserviceuserNoDomain) " -NoNewWindow -Wait -PassThru

install-packageprovider nuget -force
install-module sqlserver -allowclobber -force
import-module sqlserver
Enable-SqlAlwaysOn -ServerInstance $ComputerName -force
 
 Write-Verbose "Stop logging" -Verbose
$EndDTM = (Get-Date)
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalSeconds) Seconds" -Verbose
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalMinutes) Minutes" -Verbose
Stop-Transcript