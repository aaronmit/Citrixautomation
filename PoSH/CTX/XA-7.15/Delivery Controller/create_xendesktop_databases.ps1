Import-Module SQLServer
$Inst = "SQL01"
$Srvr = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server -ArgumentList $Inst

$DBName = "xendesktop_site"
$db = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Database($Srvr, $DBName)
$db.Create()

$DBName = "xendesktop_monitor"
$db = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Database($Srvr, $DBName)
$db.Create()

$DBName = "xendesktop_config"
$db = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Database($Srvr, $DBName)
$db.Create()

Copy-Item "\\BDT\D$\MDTProduction\Applications\Scripts\bretty\read_commit.sql" -Destination "C:\windows\temp\read_commit.sql"
sqlcmd -S $Inst -i C:\windows\temp\read_commit.sql
remove-item "C:\windows\temp\read_commit.sql" -Force

Get-SqlDatabase -ServerInstance localhost | Where { $_.Name -eq 'xendesktop_site' } | Backup-SqlDatabase
Get-SqlDatabase -ServerInstance localhost | Where { $_.Name -eq 'xendesktop_monitor' } | Backup-SqlDatabase
Get-SqlDatabase -ServerInstance localhost | Where { $_.Name -eq 'xendesktop_config' } | Backup-SqlDatabase

New-SqlHADREndpoint -Path "SQLSERVER:\SQL\sql01\Default" -Name "bag-ep-sql01" -Port 5022 -EncryptionAlgorithm Aes -Encryption Required 
New-SqlHADREndpoint -Path "SQLSERVER:\SQL\sql02\Default" -Name "bag-ep-sql02" -Port 5022 -EncryptionAlgorithm Aes -Encryption Required 
   
$primaryReplica = New-SqlAvailabilityReplica -Name sql01 -EndpointUrl “TCP://sql01.bretty.me.uk:5022” -AvailabilityMode “SynchronousCommit” -FailoverMode 'Automatic' -AsTemplate -Version 14  
$secondaryReplica = New-SqlAvailabilityReplica -Name sql02 -EndpointUrl “TCP://sql02.bretty.me.uk:5022” -AvailabilityMode “SynchronousCommit” -FailoverMode 'Automatic' -AsTemplate -Version 14

New-SqlAvailabilityGroup -InputObject sql01 -Name "bag_xendesktop_site" -AvailabilityReplica ($primaryReplica, $secondaryReplica) -Database @("xendesktop_site") -basicavailabilitygroup
Join-SqlAvailabilityGroup -Path “SQLSERVER:\SQL\sql02\Default” -Name “bag_xendesktop_site”
New-SqlAvailabilityGroup -InputObject sql01 -Name "bag_xendesktop_config" -AvailabilityReplica ($primaryReplica, $secondaryReplica) -Database @("xendesktop_config") -basicavailabilitygroup
Join-SqlAvailabilityGroup -Path “SQLSERVER:\SQL\sql02\Default” -Name “bag_xendesktop_config”
New-SqlAvailabilityGroup -InputObject sql01 -Name "bag_xendesktop_monitor" -AvailabilityReplica ($primaryReplica, $secondaryReplica) -Database @("xendesktop_monitor") -basicavailabilitygroup
Join-SqlAvailabilityGroup -Path “SQLSERVER:\SQL\sql02\Default” -Name “bag_xendesktop_monitor”

Copy-Item "C:\Program Files\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\Backup\xendesktop_site.bak" -Destination "\\sql02\c$\Program Files\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\Backup\xendesktop_site.bak"
Copy-Item "C:\Program Files\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\Backup\xendesktop_config.bak" -Destination "\\sql02\c$\Program Files\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\Backup\xendesktop_config.bak"
Copy-Item "C:\Program Files\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\Backup\xendesktop_monitor.bak" -Destination "\\sql02\c$\Program Files\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\Backup\xendesktop_monitor.bak"

Restore-SqlDatabase -ServerInstance "sql02" -Database "xendesktop_site" -norecovery
Restore-SqlDatabase -ServerInstance "sql02" -Database "xendesktop_config" -norecovery
Restore-SqlDatabase -ServerInstance "sql02" -Database "xendesktop_monitor" -norecovery

Add-SqlAvailabilityDatabase -Path "SQLSERVER:\SQL\sql02\Default\AvailabilityGroups\bag_xendesktop_site" -Database "xendesktop_site"
Add-SqlAvailabilityDatabase -Path "SQLSERVER:\SQL\sql02\Default\AvailabilityGroups\bag_xendesktop_config" -Database "xendesktop_config"
Add-SqlAvailabilityDatabase -Path "SQLSERVER:\SQL\sql02\Default\AvailabilityGroups\bag_xendesktop_monitor" -Database "xendesktop_monitor"

New-SqlAvailabilityGroupListener -Name xdsite -staticIP "192.168.100.64/255.255.255.0","192.168.103.64/255.255.255.0" -Port 1433 -Path "SQLSERVER:\Sql\sql01\DEFAULT\AvailabilityGroups\bag_xendesktop_site"
New-SqlAvailabilityGroupListener -Name xdconfig -staticIP "192.168.100.65/255.255.255.0","192.168.103.65/255.255.255.0" -Port 1433 -Path "SQLSERVER:\Sql\sql01\DEFAULT\AvailabilityGroups\bag_xendesktop_config"
New-SqlAvailabilityGroupListener -Name xdmonitor -staticIP "192.168.100.66/255.255.255.0","192.168.103.66/255.255.255.0" -Port 1433 -Path "SQLSERVER:\Sql\sql01\DEFAULT\AvailabilityGroups\bag_xendesktop_monitor"
