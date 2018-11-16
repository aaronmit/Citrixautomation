## Script Setup

## Logging Declarations

$version = "1.00"
$logPath = 'D:'
$logName = 'generalise.log'
$logLocation = $logPath + '\' + $logName

## Machine specifics declarations

$computerName = $env:computername
New-PSDrive -Name HKU -Root HKEY_USERS -PSProvider Registry
$ErrorActionPreference = "Stop"
try { $WriteCacheType = & 'C:\Program Files\Citrix\Provisioning Services\GetPersonality.exe' '$WriteCacheType' /o}
catch { Log-Write -LineValue "!!!ERROR!!! $_" }
$ErrorActionPreference = "Continue"


## Forward Declaration of Functions

Function ClearCCMCache {
## Function setup
$UIResourceMgr = New-Object -ComObject UIResource.UIResourceMgr
$ErrorActionPreference = "Stop"
try { 
$Cache = $UIResourceMgr.GetCacheInfo()
$CacheElements = $Cache.GetCacheElements()
}
catch { Log-Write -LineValue "!!!ERROR!!! $_" }
$ErrorActionPreference = "Continue"

Foreach ($Element in $CacheElements)

{ 
## Deleting each SCCM cache element
Log-Write -LineValue "Deleteing CacheElement with PackageID $($Element.ContentID)"
Log-Write -LineValue "In folder location $($Element.Location)"
$ErrorActionPreference = "Stop"
try { $cache.DeleteCacheElement($Element.CacheElementID)}
catch { Log-Write -LineValue "!!!ERROR!!! $_" }
$ErrorActionPreference = "Continue"

}
## Deleting any remaining orphaned SCCM cache folders
Log-Write -LineValue "Deleting any remaining orphaned SCCM cache folders"
try { Remove-Item -Path D:\ccmcache\* -Recurse -Force -ErrorAction Stop}
catch { Log-Write -LineValue "!!!ERROR!!! $_" }


}

Function Log-Start {

    #Check if file exists and delete if it does
    If((Test-Path -Path $logLocation)){
        Remove-Item -Path $logLocation -Force
    }
    
    #Create file and start logging
    #New-Item -Path $LogPath -name $LogName -ItemType File
    Out-File -FilePath $logLocation -Encoding unicode

    Add-Content -Path $logLocation -Value "#############################################"
    Add-Content -Path $logLocation -Value "Started processing at [$([DateTime]::Now)]."
    Add-Content -Path $logLocation -Value "#############################################"
    Add-Content -Path $logLocation -Value "Running script on $computerName."
    Add-Content -Path $logLocation -Value "Running version on $version."
    Add-Content -Path $logLocation -Value "#############################################"
    Add-Content -Path $logLocation -Value ""

}

Function Log-End {

    Add-Content -Path $logLocation -Value "#############################################"
    Add-Content -Path $logLocation -Value "Ended processing at [$([DateTime]::Now)]."
    Add-Content -Path $logLocation -Value "#############################################"

}

Function Log-Write {

  Param ([Parameter(Mandatory=$true)][string]$LineValue)
  
  Process{

    $time = Get-Date
    $LineValue = "#### " + $time.ToLongTimeString() + " #### $LineValue"
    Add-Content -Path $logLocation -Value $LineValue
  
    #Write to screen for debug mode
    Write-Debug $LineValue

    $LineValue = $null
    $time = $null
  }

}


## Begin main script

If ($WriteCacheType -eq "0") {

Log-Start

Log-Write -LineValue "Detected private image mode $computerName"

## Deleting McAfee AgentGUID
Log-Write -LineValue 'Deleting McAfee AgentGUID'
try { Remove-ItemProperty -Name AgentGUID -Path 'HKLM:\SOFTWARE\Wow6432Node\Network Associates\ePolicy Orchestrator\Agent' -ErrorAction Stop}
catch { Log-Write -LineValue "!!!ERROR!!! $_" }

## Deleting AppSense Machine ID
Log-Write -LineValue 'Deleting AppSense Machine ID'
try { Remove-ItemProperty -Name 'machine id' -Path 'HKLM:\SOFTWARE\AppSense Technologies\Communications Agent' -ErrorAction Stop}
catch { Log-Write -LineValue "!!!ERROR!!! $_" }

## Deleting AppSense Group ID
Log-Write -LineValue 'Deleting AppSense Group ID'
try { Remove-ItemProperty -Name 'group id' -Path 'HKLM:\SOFTWARE\AppSense Technologies\Communications Agent' -ErrorAction Stop}
catch { Log-Write -LineValue "!!!ERROR!!! $_" }

## Deleting AppSense self register
Log-Write -LineValue 'Deleting AppSense self register'
try { Remove-ItemProperty -Name 'self register' -Path 'HKLM:\SOFTWARE\AppSense Technologies\Communications Agent' -ErrorAction Stop}
catch { Log-Write -LineValue "!!!ERROR!!! $_" }

## Deleting System Wide RunMRU
Log-Write -LineValue 'Deleting System Wide RunMRU Keys'
try { Remove-ItemProperty -Name * -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Terminal Server\Install\Software\Microsoft\Windows\CurrentVersion\Explorer\RunMRU' -ErrorAction Stop}
catch { Log-Write -LineValue "!!!ERROR!!! $_" }
try { Remove-ItemProperty -Name * -Path 'HKU:\.DEFAULT\Software\Microsoft\Windows\CurrentVersion\Explorer\RunMRU' -ErrorAction Stop}
catch { Log-Write -LineValue "!!!ERROR!!! $_" }

## Remove the SCCM Hardware Scan Inventory Action ID 1 in WMI
Log-Write -LineValue "Remove the SCCM Hardware Scan Inventory Action ID 1 in WMI"
try { Get-WmiObject -Query "SELECT * FROM inventoryActionStatus WHERE InventoryActionID = '{00000000-0000-0000-0000-000000000001}'" -Namespace "ROOT\ccm\invagt" | Remove-WmiObject -ErrorAction Stop}
catch { Log-Write -LineValue "!!!ERROR!!! $_" }
#Get-WmiObject -Query "SELECT * FROM inventoryActionStatus" -Namespace "ROOT\ccm\invagt" | Remove-WmiObject

## Remove the SCCM Software Scan Inventory Action ID 2 in WMI
Log-Write -LineValue "Remove the SCCM Software Scan Inventory Action ID 2 in WMI"
try { Get-WmiObject -Query "SELECT * FROM inventoryActionStatus WHERE InventoryActionID = '{00000000-0000-0000-0000-000000000002}'" -Namespace "ROOT\ccm\invagt" | Remove-WmiObject -ErrorAction Stop}
catch { Log-Write -LineValue "!!!ERROR!!! $_" }

## Clear the SCCM Local Cache
ClearCCMCache

## Stop the SCCM Client
#Log-Write -LineValue 'Stopping SCCM Client'
#try { Stop-Service CcmExec -ErrorAction Stop}
#catch { Log-Write -LineValue "!!!ERROR!!! $_" }

## Copy and remove the SCCM Client Config File from the C: drive (and Citrix backup) to the D: drive
## Log-Write -LineValue 'Moving SMSCFG.ini to D:'
## try { Copy-Item -Path c:\windows\SMSCFG.ini -Destination d:\smscfg.ini -Force -ErrorAction Stop}
## catch { Log-Write -LineValue "!!!ERROR!!! $_" }

# Commented out as this is not required due to PVS managing a locally persisted copy of the CCM config and certs
#Log-Write -LineValue 'Deleting CCMCFG.BAK from LocallyPersistedData'
#try { Remove-Item -Path c:\ProgramData\Citrix\PvsAgent\LocallyPersistedData\CCMData\CCMCFG.BAK -ErrorAction Stop}
#catch { Log-Write -LineValue "!!!ERROR!!! $_" }

# Commented out as this is not required due to PVS managing a locally persisted copy of the CCM config and certs
## Delete the SMS Software Distribution Values
#Log-Write -LineValue 'Removing SMS Software Distribution Values'
#try { Remove-ItemProperty -Name * -Path 'HKLM:\Software\Microsoft\SMS\Mobile Client\Software Distribution' -ErrorAction Stop}
#catch { Log-Write -LineValue "!!!ERROR!!! $_" }

# Commented out as this is not required due to PVS managing a locally persisted copy of the CCM config and certs
## Remove the SCCM Certs
#Log-Write -LineValue 'Deleting the SMS Client Certificates'
#try { Remove-Item -Path Cert:\LocalMachine\SMS -DeleteKey -Confirm -Force -Recurse -ErrorAction Stop}
#catch { Log-Write -LineValue "!!!ERROR!!! $_" }

## Empty the temp, AppSenseVirtual and AppSense Upload folders
Log-Write -LineValue 'Deleting the temp folder contents'
try { Remove-Item -Path 'C:\temp\*' -Recurse -ErrorAction Stop}
catch { Log-Write -LineValue "!!!ERROR!!! $_" }

Log-Write -LineValue 'Deleting the AppSenseVirtual Folder Contents'
try { Remove-Item -Path 'C:\AppSenseVirtual\*' -Recurse -ErrorAction Stop}
catch { Log-Write -LineValue "!!!ERROR!!! $_" }

Log-Write -LineValue 'Deleting the AppSense Uploads Folder Contents'
try { Remove-Item -Path 'C:\Program Files\AppSense\Management Center\Communications Agent\upload\*' -Recurse -ErrorAction Stop}
catch { Log-Write -LineValue "!!!ERROR!!! $_" }

#Log-Write -LineValue 'Defragging the C: drive'
#defrag.exe C: /U /V >> $logLocation

# Run an On-Demand Virus Scan
Log-Write -LineValue 'Running VirusScan'
& "C:\Program Files (x86)\McAfee\VirusScan Enterprise\scan32.exe" /AlwaysExit /Task "{21221C11-A06D-4558-B833-98E8C7F6C4D2}"

# Sleep for 30 seconds to allow the scan to begin
Start-Sleep 30

# Check to see if the McAfee scan64.exe is still running
If (get-Process "scan64" -ErrorAction SilentlyContinue | Where-Object {-not $_.HasExited }) {
    Do {
        Write-Host "The McAfee On-Demand Scan is still running... Wait 5 minute to check again"
        Start-Sleep -Seconds 500
    If (get-Process "scan64" -ErrorAction SilentlyContinue | Where-Object {$_.id }) {
        $processExit = $null
    }
    else
    {
        $processExit = $true
    }
    }
    Until ($processExit)
    Log-Write -LineValue "The McAfee On-Demand Scan has now finished"
    }
    Else {
    Log-Write -LineValue "The McAfee On-Demand Scan is not running"
    } 

## Copy master image generalisation.log to the C:, enabling easy validation from target devices
Log-Write -LineValue 'Copying D:\generalise.log to C:'
Log-End
try { Copy-Item -Path d:\generalise.log -Destination C:\generalise.log -Force -ErrorAction Stop}
catch { Log-Write -LineValue "!!!ERROR!!! $_" }

}
Else
{

Log-Start

Log-Write -LineValue "Device is not in private mode: $computerName"

## Backing up the App-V Application Inventory
Log-Write -LineValue 'Backing up App-V Application Inventory Registry'
REG EXPORT 'HKLM\Software\Wow6432Node\Microsoft\SoftGrid\4.5\Client\Applications' "$logPath\appv_applications.reg" /y >> $logLocation

## Backing up the App-V Packages Inventory
Log-Write -LineValue 'Backing up App-V Package Inventory Registry'
REG EXPORT 'HKLM\Software\Wow6432Node\Microsoft\SoftGrid\4.5\Client\Packages' "$logPath\appv_packages.reg" /y >> $logLocation

## Clear the SCCM Local Cache
ClearCCMCache

## Stop the SCCM Client
## Log-Write -LineValue 'Stopping SCCM Client'
## try { Stop-Service CcmExec -ErrorAction Stop}
## catch { Log-Write -LineValue "!!!ERROR!!! $_" }

## Copy the SCCM Client Config File from the C: drive (and Citrix backup) to the D: drive
## Log-Write -LineValue 'Copying SMSCFG.ini to D:'
## try { Copy-Item -Path c:\windows\SMSCFG.ini -Destination d:\smscfg.ini -Force -ErrorAction Stop}
## catch { Log-Write -LineValue "!!!ERROR!!! $_" }

Log-End

}

## Clear down

Remove-PSDrive -Name HKU