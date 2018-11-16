## Script Setup

## Logging Declarations

$version = "1.00"
$logPath = 'D:'
$logName = 'startup.log'
$logLocation = $logPath + '\' + $logName

## Machine specifics declarations

## Globals
$computerName = $env:computername
$SCCMClient = [wmiclass]"\\$computerName\root\ccm:SMS_Client"
$SCCMInstalled = (get-service -name ccmexec*).name -eq "ccmexec"
$WriteCacheType = & 'C:\Program Files\Citrix\Provisioning Services\GetPersonality.exe' '$WriteCacheType' /o

## Forward Declaration of Functions

Function SCCMCycle {
        # Check to see if the SMS Host Agent service has started
        If ((Get-Service -Name CCMExec).Status -ne 'Running') 
        {
                Do 
                {
                        Log-Write -LineValue "The SMS Agent Host service has not yet started waiting 3 seconds..."
                        Start-Sleep -Seconds 3
                        $recheck = (Get-Service -Name CCMExec).Status
                }
                Until ($recheck -eq 'Running')
         }
         Else
         {
                Log-Write -LineValue "The SMS Agent Host service is now running."
         }

        #Allow everything to register properly
        Start-Sleep -Seconds 90
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

If ($WriteCacheType -match "[0-9]|10") {

Log-Start

Log-Write -LineValue "Detected PVS Device: $computerName"

## Restoring the App-V Application Inventory
Log-Write -LineValue 'Restoring the App-V Application Inventory'
$ErrorActionPreference = "Stop"
try { REG IMPORT "$logPath\appv_applications.reg" 2>&1 }
catch { If ($_ -notlike "The operation completed successfully.") { Log-Write -LineValue "!!!ERROR!!! $_" } }

## Restoring the App-V Packages Inventory
Log-Write -LineValue 'Restoring the App-V Packages Inventory'
try { REG IMPORT "$logPath\appv_packages.reg" 2>&1 }
catch { If ($_ -notlike "The operation completed successfully.") { Log-Write -LineValue "!!!ERROR!!! $_" } }
$ErrorActionPreference = "Continue"

## Restarting the App-V Services
Log-Write -LineValue 'Restarting App-V Services'
If ((Get-Service sftlist).status -eq "Running") {
    Log-Write -LineValue 'App-V Services running. Attempting restart'
    try { Restart-Service sftvsa -Force -ErrorAction Stop}
    catch { Log-Write -LineValue "!!!ERROR!!! $_" }
}
Else
{
    Log-Write -LineValue 'App-V Services not running. Starting'
    try { Start-Service sftlist -ErrorAction Stop}
    catch { Log-Write -LineValue "!!!ERROR!!! $_" }
}

## Check to see if the SCCM Service is started and run the following actions
#IF ($SCCMInstalled -eq $true) {
#    SCCMCycle
#    Log-Write -LineValue "Run the Hardware Inventory Cycle"
#    try { $SCCMClient.TriggerSchedule("{00000000-0000-0000-0000-000000000001}") -ErrorAction Stop}
#    catch { Log-Write -LineValue "!!!ERROR!!! $_" }
#    Log-Write -LineValue "Run the Evaluate Machine Policies Cycle"
#    try { $SCCMClient.TriggerSchedule("{00000000-0000-0000-0000-000000000022}") -ErrorAction Stop}
#    catch { Log-Write -LineValue "!!!ERROR!!! $_" }

#    
#    If ($computerName -contains "ACL-XD7-VXX*" -or $computerName -contains "ACL-XD7-V000" -or $computerName -contains "ACL-XD7-V999") {
#        Log-Write -LineValue "Master image detected running SCCM Cycle and Software Updates"
#        Log-Write -LineValue "Run the Software Updates Evaluation Cycle"
#        try { $SCCMClient.TriggerSchedule("{00000000-0000-0000-0000-000000000108}") -ErrorAction Stop}
#        catch { Log-Write -LineValue "!!!ERROR!!! $_" }

#    }
#    ELSE
#    {
#          Log-Write -LineValue "Run the Application Deployment Evaluation Cycle"
#        try { $SCCMClient.TriggerSchedule("{00000000-0000-0000-0000-000000000121}") -ErrorAction Stop}
#        catch { Log-Write -LineValue "!!!ERROR!!! $_" }
#    }
#}

Log-End