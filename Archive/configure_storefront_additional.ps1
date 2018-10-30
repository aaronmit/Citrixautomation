<#   
.SYNOPSIS   
    Adds the StoreFront Server to an existing StoreFront Server Group
.DESCRIPTION 
    Adds the StoreFront Server to an existing StoreFront Server Group
.NOTES
    Creation Date:          03/07/2018
.CHANGE CONTROL
    Name                    Version         Date                Change Detail
    David Brett             1.0             03/07/2018          Function Creation
#>

# Determine where to do the logging
$logPS = "C:\Windows\Temp\configure_storefront_additional.log"

Write-Verbose "Setting Arguments" -Verbose
$StartDTM = (Get-Date)

Start-Transcript $LogPS

# Import StoreFront PowerShell modules
. "C:\Program Files\Citrix\Receiver StoreFront\Scripts\ImportModules.ps1"
 
$SFExistingServer = "web01"

# Locations
$RemoteConfigFolder = "_CONFIG"
$RemoteConfigPath = "\\$SFExistingServer\c$"
$LocalConfigFolder = "_CONFIG"
$LocalConfigPath = "C:"

# Check if folders and/or files already exist
if((Test-Path $RemoteConfigPath\$RemoteConfigFolder) -eq 0 ) {
    mkdir $RemoteConfigPath\$RemoteConfigFolder
}
if((Test-Path $RemotePasscodeScript) -ne 0) {
    Remove-Item $RemotePasscodeScript
    }
if((Test-Path $RemoteConfigPath\$RemoteConfigFolder\Passcode.txt) -ne 0) {
    Remove-Item $RemoteConfigPath\$RemoteConfigFolder\Passcode.txt
}

# Files and scripts
$RemotePasscodeScript = "$RemoteConfigPath\$RemoteConfigFolder\SFPasscodeScript.ps1"
$LocalPasscodeScript = "$LocalConfigPath\$LocalConfigFolder\SFPasscodeScript.ps1"

# Create PowerShell Session object
$PSSession = New-PSSession -ComputerName $SFExistingServer

# Create script on existing StoreFront server
Add-Content $RemotePasscodeScript ". ""C:\Program Files\Citrix\Receiver StoreFront\Scripts\ImportModules.ps1"""
Add-Content $RemotePasscodeScript "Start-DSClusterJoinService"
Add-Content $RemotePasscodeScript "`$Passcode = Get-DSXdServerGroupJoinServicePasscode"
Add-Content $RemotePasscodeScript "`$Passcode.Passcode.ToString() > $LocalConfigPath\$LocalConfigFolder\Passcode.txt"

# Run script on existing StoreFront server
schtasks /Create /F /TN SFPasscodeScript /S $SFExistingServer /RU "SYSTEM" /TR "powershell.exe -File $LocalPasscodeScript" /SC once /ST 23:30
schtasks /Run /TN SFPasscodeScript /S $SFExistingServer
Start-Sleep -seconds 30
$SFPasscode = Get-Content -Path "$RemoteConfigPath\$RemoteConfigFolder\Passcode.txt"
schtasks /Delete /TN SFPasscodeScript /S $SFExistingServer /F
Remove-Item $RemoteConfigPath\$RemoteConfigFolder\Passcode.txt
Remove-Item $RemotePasscodeScript

# Join new server to StoreFront group and wait a while for completion
Start-DSClusterJoinService
Start-DSXdServerGroupMemberJoin -authorizerHostName $SFExistingServer -authorizerPasscode $SFPasscode
Start-Sleep -s 300
Invoke-Command -Session $PSSession -Scriptblock {
	. "C:\Program Files\Citrix\Receiver StoreFront\Scripts\ImportModules.ps1"
	Stop-DSClusterJoinService
}

Start-Sleep -seconds 30
Stop-DSClusterJoinService

$PSSession = New-PSSession -computerName $SFExistingServer
Invoke-Command -Session $PSSession -Scriptblock {
	Add-PSSnapin Citrix*
	Start-DSConfigurationReplicationClusterUpdate -confirm:$FALSE
}

Start-Sleep -seconds 120

Write-Verbose "Stop logging" -Verbose
$EndDTM = (Get-Date)
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalSeconds) Seconds" -Verbose
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalMinutes) Minutes" -Verbose
Stop-Transcript