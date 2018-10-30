# Determine where to do the logging
$logPS = "C:\Windows\Temp\configure_windows_clustering.log"

Write-Verbose "Setting Arguments" -Verbose
$StartDTM = (Get-Date)

Start-Transcript $LogPS

$PrimaryNode = "sql01"
$secondarynode = "sql02"
$fswNode = "sql03"
$ClusterNameShort = "SQLCluster"
$Domain = "bretty"
$ClusterName = "CN=SQLCluster,OU=Database Servers,OU=Servers,OU=Deployment,DC=bretty,DC=me,DC=uk"
$PrimaryIP = "192.168.100.61"
$SecondaryIP = "192.168.103.61"
$filesharewitness = "\\sql03\c$\"
$fswShare = "\\sql03\fsw"

# Configure Windows Clustering
#==================

Install-WindowsFeature -Name Failover-Clustering -IncludeManagementTools
$Session = new-pssession -computername $secondarynode
invoke-command -session $session { Install-WindowsFeature -Name Failover-Clustering -IncludeManagementTools }
New-Cluster -Name $ClusterName -Node $PrimaryNode,$secondarynode -StaticAddress $PrimaryIP,$SecondaryIP -nostorage

Move-ClusterGroup "cluster group" -Node sql01 -Wait 0
start-sleep -seconds 20
 
If ((Test-Path $filesharewitness) -eq $false)
{
New-Item -Path $filesharewitness -ItemType Container
}
 
#Set file share permissions
Start-Process -FilePath "icacls.exe" -ArgumentList """$filesharewitness"" /grant ""$Domain\$ClusterNameShort$"":(OI)(CI)(F) /C" -NoNewWindow -Wait
Start-Process -FilePath "icacls.exe" -ArgumentList """$filesharewitness"" /grant ""$Domain\$PrimaryNode$"":(OI)(CI)(F) /C" -NoNewWindow -Wait
Start-Process -FilePath "icacls.exe" -ArgumentList """$filesharewitness"" /grant ""$Domain\$secondarynode$"":(OI)(CI)(F) /C" -NoNewWindow -Wait

$Sessionfsw = new-pssession -computername $fswNode
invoke-command -session $sessionfsw { New-SmbShare -Name fsw -Path C:\fsw -FullAccess Everyone -ReadAccess Users }
 
Set-ClusterQuorum -NodeAndFileShareMajority $fswShare

Get-ClusterResource -Name $ClusterNameShort | Set-ClusterParameter -Name HostRecordTTL -Value 5

 Write-Verbose "Stop logging" -Verbose
$EndDTM = (Get-Date)
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalSeconds) Seconds" -Verbose
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalMinutes) Minutes" -Verbose
Stop-Transcript