<#   
.SYNOPSIS   
    Configures the new UI on the StoreFront Server
.DESCRIPTION 
    Configures the new UI on the StoreFront Server
.NOTES
    Creation Date:          03/07/2018
.CHANGE CONTROL
    Name                    Version         Date                Change Detail
    David Brett             1.0             03/07/2018          Function Creation
#>

# Determine where to do the logging
$logPS = "C:\Windows\Temp\configure_storefront_new_ui.log"

Write-Verbose "Setting Arguments" -Verbose
$StartDTM = (Get-Date)

Start-Transcript $LogPS

# Use New UI
$UseNewUI = "yes"
$SFPathWeb = "/Citrix/BrettyWeb"

# Use New UI
If($UseNewUI -eq "yes"){
    Remove-Item -Path "C:\iNetPub\wwwroot\$SFPathWeb\receiver\css\*" -Recurse -Force
    Copy-Item -Path "\\bdt\mdtproduction$\Applications\Scripts\bretty\custom\storefront\workspace\receiver\*" -Destination "C:\iNetPub\wwwroot\$SFPathWeb\receiver" -Recurse -Force
    Copy-Item -Path "\\bdt\mdtproduction$\Applications\Scripts\bretty\custom\storefront\workspace\receiver.html" -Destination "C:\iNetPub\wwwroot\$SFPathWeb" -Recurse -Force
    Copy-Item -Path "\\bdt\mdtproduction$\Applications\Scripts\bretty\custom\storefront\workspace\receiver.appcache" -Destination "C:\iNetPub\wwwroot\$SFPathWeb" -Recurse -Force
    iisreset
}

Write-Verbose "Stop logging" -Verbose
$EndDTM = (Get-Date)
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalSeconds) Seconds" -Verbose
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalMinutes) Minutes" -Verbose
Stop-Transcript