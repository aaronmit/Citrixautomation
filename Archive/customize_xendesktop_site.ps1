Write-Verbose "Setting Arguments" -Verbose
$StartDTM = (Get-Date)

$MyConfigFileloc = ("Settings.xml")
[xml]$MyConfigFile = (Get-Content $MyConfigFileLoc)

$Vendor = "Citrix"
$Product = "XenDesktop"
$Version = $MyConfigFile.Post.Version
$LogPS = "${env:SystemRoot}" + "\Temp\Customize $Vendor $Product $Version Site PS Wrapper.log"

$FullAdminGroup = "bretty\xd admins"
$PrimaryZoneName = "Liphook"
$vSphereHosting = "no"
$vCenterURL = "https://192.168.1.100"
$TempvSphereCertPath = "c:\windows\temp\vc.cer"
$vSphereHostConnectionName = "bretty_vsphere"
$vSphereHostAddress = "192.168.1.100"
$vSphereUserName = "administrator@vsphere.local"
$vSpherePassword = "Jp1hlwci.021978"
$vSpherehType = "VCenter"

$HostConnectionName = "VMware"
$NetworkName = "vlan_100"
$StorageName = "ssd-ds2"
$DataCenterName = "Liphook"
$ComputeResourceName = "192.168.1.7"
$HostingInfrastructureName = "VMware-Resources"

Start-Transcript $LogPS

Add-PSSnapin Citrix.*

# Add Administrator to Site
New-AdminAdministrator -AdminAddress $env:COMPUTERNAME -Name $FullAdminGroup
Add-AdminRight -AdminAddress $env:COMPUTERNAME -Administrator $FullAdminGroup -Role 'Full Administrator' -All

# Rename the primary Zone 
Rename-ConfigZone -Name "Primary" -NewName $PrimaryZoneName

# Add vSphere Hosting Connection and resources
if ($vSphereHosting -eq "yes") {
    
    # Connect to vSphere and import the certificate to trusted root
    $webRequest = [Net.WebRequest]::Create($vCenterURL)
    try { $webRequest.GetResponse() } catch {}
    $cert = $webRequest.ServicePoint.Certificate
    $bytes = $cert.Export([Security.Cryptography.X509Certificates.X509ContentType]::Cert)
    set-content -value $bytes -encoding byte -path $TempvSphereCertPath
    Import-Certificate -FilePath $TempvSphereCertPath -CertStoreLocation Cert:\LocalMachine\Root

    # Get the Certificate Thumbprint
    $certPrint = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
    $certPrint.Import($TempvSphereCertPath)

    # Add the Connection UID
    $vSphereHostAddress = "https://" + $vSphereHostAddress + "/sdk"
    $Connectionuid = New-Item -ConnectionType $vSpherehType -CustomProperties "" -HypervisorAddress  $vSphereHostAddress -Path @("XDHyp:\Connections\VMware") -Password $vSpherePassword -UserName $vSphereUserName -SSLThumbprint $certPrint.Thumbprint -persist | select HypervisorConnectionUid

    # Get the local host fqdn for the Controller
    $computername = (Get-WmiObject win32_computersystem).DNSHostName + "." +(Get-WmiObject win32_computersystem).Domain
    $URL = "$computername" + ":80"

    # Commit the new connection
    New-BrokerHypervisorConnection -AdminAddress $URL -HypHypervisorConnectionUid $connectionuid.HypervisorConnectionUid

    # Add the resources to the connection
    $hostSpecificSuffix = "\$DataCenterName.datacenter\$ComputeResourceName.computeresource\"

    # Build string for hosting unit resources
    $hRootPath = "XDHyp:\Connections\"+$HostConnectionName+$hostSpecificSuffix   
    $networkPath = $hRootPath + $NetworkName + ".network"
    $storagePath = $hRootPath + $StorageName + ".storage"
    $pvdStoragePath = $hRootPath + $StorageName + ".storage"

    # Create the hosting unit
    $hInf = $null
    $hInf = New-Item -Path XDHyp:\HostingUnits `
                     -Name $HostingInfrastructureName `
                     -HypervisorConnectionName $HostConnectionName `
                     -RootPath $hRootPath `
                     -NetworkPath $networkPath `
                     -StoragePath $storagePath `
                     -PersonalvDiskStoragePath $pvdStoragePath
}

Write-Verbose "Stop logging" -Verbose
$EndDTM = (Get-Date)
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalSeconds) Seconds" -Verbose
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalMinutes) Minutes" -Verbose
Stop-Transcript
