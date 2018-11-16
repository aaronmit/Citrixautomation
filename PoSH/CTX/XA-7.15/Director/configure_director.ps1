# Determine where to do the logging
$logPS = "C:\Windows\Temp\configure_director.log"

Write-Verbose "Setting Arguments" -Verbose
$StartDTM = (Get-Date)

Start-Transcript $LogPS

# Set up Variables
$Broker = "xd.bretty.me.uk"
$DomainName = "bretty.me.uk"
$SessionTimeout = "60"
$LogonASPXFile = "c:\inetpub\wwwroot\director\logon.aspx"

# Read each line of the file and pre-populate the domain name
$OldText = "TextBox ID=""Domain"" runat=""server"""
$NewText = "TextBox ID=""Domain"" runat=""server"" Text=""$DomainName"" readonly=""true"""
$Content = Get-Content $LogonASPXFile
$ContentNew = ""
Foreach ( $Line in $Content ) {
	$Line = ( $Line -replace $OldText, $NewText) + "`r`n"
	$ContentNew = $ContentNew + $Line
}
Set-Content $LogonASPXFile -value $ContentNew -Encoding UTF8

# Set the Director Broker
$xml = [xml](Get-Content "C:\inetpub\wwwroot\Director\web.config")
$node = $xml.configuration.appSettings.add
$nodeAddress = $node | where {$_.Key -eq 'Service.AutoDiscoveryAddresses'}
$nodeAddress.Value = $Broker
$xml.Save("C:\inetpub\wwwroot\Director\web.config")

# Change the Session Timeout
$xml = [xml](Get-Content "C:\inetpub\wwwroot\Director\web.config")
$node = $xml.configuration."system.web".sessionState
$node.timeout = $SessionTimeOut
$xml.Save("C:\inetpub\wwwroot\Director\web.config")

# Disable SSL Check
$xml = [xml](Get-Content "C:\inetpub\wwwroot\Director\web.config")
$node = $xml.configuration.appSettings.add | where {$_.Key -eq 'UI.EnableSslCheck'}
$node.value = "false"
$xml.Save("C:\inetpub\wwwroot\Director\web.config")

Write-Verbose "Stop logging" -Verbose
$EndDTM = (Get-Date)
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalSeconds) Seconds" -Verbose
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalMinutes) Minutes" -Verbose
Stop-Transcript