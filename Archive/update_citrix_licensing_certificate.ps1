# Determine where to do the logging
$logPS = "C:\Windows\Temp\update_citrix_licensing_certificate.log"

Write-Verbose "Setting Arguments" -Verbose
$StartDTM = (Get-Date)

Start-Transcript $LogPS

# Parameters
#==================

# Update the Citrix Licensing Certificate
#==================
copy-item "\\bdt\mdtproduction$\Applications\Scripts\bretty\certificates\internal\wildcard\wildcard.cer" -Destination "C:\Program Files (x86)\Citrix\Licensing\WebServicesForLicensing\Apache\conf\server.crt"
copy-item "\\bdt\mdtproduction$\Applications\Scripts\bretty\certificates\internal\wildcard\wildcard_decrypted.key" -Destination "C:\Program Files (x86)\Citrix\Licensing\WebServicesForLicensing\Apache\conf\server.key"
copy-item "\\bdt\mdtproduction$\Applications\Scripts\bretty\certificates\internal\wildcard\wildcard.cer" -Destination "C:\Program Files (x86)\Citrix\Licensing\LS\conf\server.crt"
copy-item "\\bdt\mdtproduction$\Applications\Scripts\bretty\certificates\internal\wildcard\wildcard_decrypted.key" -Destination "C:\Program Files (x86)\Citrix\Licensing\LS\conf\server.key"

# Restart the Licensing Service
#==================
restart-service "Citrix Licensing"

Write-Verbose "Stop logging" -Verbose
$EndDTM = (Get-Date)
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalSeconds) Seconds" -Verbose
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalMinutes) Minutes" -Verbose
Stop-Transcript
