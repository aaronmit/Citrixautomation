$logFile = "C:\Windows\Temp\Join_XA.log"
 
Start-Transcript $logFile
Write-Output "Logging to $logFile"

Add-PSSnapin Citrix.*
Add-XDController -AdminAddress localhost -SiteControllerAddress xd01.bretty.me.uk
Set-BrokerSite -TrustRequestsSentToTheXmlServicePort $true

Stop-Transcript