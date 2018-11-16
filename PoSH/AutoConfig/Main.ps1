# Jo Burgess - Metaphor IT November 2018

# Script to automate Citrix Deployments.
# The script requires a ClientName variable which defines the name of the config file.
# If the script doesn't find the config file in the same folder as the script then it generates a new one by asking questions.

# Uses modified versions of Bretty's scripts
# I modified them because Bretty embeds the variables, they now accept parameters.

# Run the script on each component server.

#####################################################################################
#################################### Parameters #####################################
#####################################################################################
# Parameters are declared

Param (
    [Parameter(Mandatory=$True)] 
    [string]$clientname,
    [string]$DomainName,
    [switch]$IsFatVM,
    [switch]$IsMCS,
# Not doing any domain manipulation in this version.
#    [string]$WorkerOU,
    [switch]$IsUPM,
    [string]$PathToUPM,
    [string]$BaseDDCName,
    [string]$BaseSFName,
    [string]$BaseVDAName,
    [switch]$Office365C2R,
    [string]$PathToSoftware,
    [switch]$IsServerVDA,
    [String]$SQLServer,
    [string]$LicenseServer
    )

#####################################################################################
#################################### Script Prep ####################################
#####################################################################################
# Script prepares variables and validates the config file

Start-Transcript ".\$clientname Transcript.log"

$ScriptDir = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent

Set-Location $ScriptDir

[xml]$MetaphorDefaults = (Get-Content "./MetaphorDefaults.xml")

# Set variables For the configuration file

$ConfigFile = ".\$clientname.csv"

# If the config file exists then the scrpt pulls the variables in here. 
# Variables can still be Null, the contents of the file can be garbage.
# Validation will take place later. 

if (test-path $ConfigFile) {
    Write-Host "Config file for $ClientName found. Setting variables from config file."
    $Config = Import-Csv $ConfigFile
    $ClientName = $Config.ClientName
    $DomainName = $Config.DomainName
    $IsFatVM = $Config.IsFatVM
    $IsMCS = $Config.IsMCS
# Not doing any domain manipulation in this version.
#    $WorkerOU = $Config.WorkerOU
    $IsUPM = $Config.IsUPM
    $PathToUPM = $Config.PathToUPM
    $BaseDDCName = $Config.BaseDDCName
    $BaseSFName = $Config.BaseSFName
    $BaseVDAName = $Config.BaseVDAName
    $Office365C2R = $Config.Office365C2R
    $PathToSoftware = $Config.PathToSoftware
    $IsServerVDA = $Config.IsServerVDA
}

# Oh no! The config file is missing entirely!
# This will generate a new one.

else {
    Write-Host "Config file is missing. Generating..."
    GenerateConfigFile
}

# Now is later.
# The script checks to see if any of the required variables are blank.
# If the script finds null values it will generate a new config file (strong but probably required). 

Write-host "Validating config file"
if (!$ClientName -or !$DomainName -or !$IsFatVM -or !$IsUPM -or !$BaseDDCName -or !$BaseSFName -or !$BaseVDAName -or !$Office365C2R -or !$PathToSoftware -or !$IsServerVDA -or !$SQLServer) {
    Write-Host "Config file is invalid. Deleting invalid file."
    Remove-Item -Path $ConfigFile | Out-Null
    Write-Host "Generating new config file."
    GenerateConfigFile
}

# If the variables all contain values then the script considers the config file valid.
# The script does not set values

else {
    Write-Host "Config file validated successfully."
}

# Variables for the XenApp Site

$SiteDB = $MetaphorDefaults.Delivery.SiteDB
$MonitDB = $MetaphorDefaults.Delivery.MonitDB
$LogDB = $MetaphorDefaults.Delivery.LogDB
$SiteName = $MetaphorDefaults.Delivery.SiteName

# XML for Office

$OfficeXML = @"
<Configuration>

  <Add Sourcepath="$PathToSoftware" OfficeClientEdition="32" Channel="Broad">
    <Product ID="O365ProPlusRetail">
      <Language ID="en-us" />
    </Product>
  </Add>

  <Updates Enabled="TRUE" Channel="Broad" />

  <Display Level="None" AcceptEULA="TRUE" />

</Configuration>
"@

# Fully qualify server names

$DDC1 = $BaseDDCName+"01."+$DomainName
$DDC2 = $BaseDDCName+"02."+$DomainName

$SF1 = $BaseSFName+"01."+$DomainName
$SF2 = $BaseSFName+"02."+$DomainName

# Create Group Policy Objects

New-GPO -Name "Citrix-User"
New-GPO -Name "Citrix-Computer"
New-GPO -Name "Citrix-Loopback"

#####################################################################################
##################################### Functions #####################################
#####################################################################################
# Functions to manipulate the config file
# Functions to configure each server type


function GenerateConfigFile {
    $ColHeaders = "ClientName, DomainName, IsFatVM, IsMCS, IsUPM, PathToUPM, BaseDDCName, BaseSFName, BaseVDAName, Office365C2R, PathToSoftware, IsServerVDA, SQLServer"
    Write-Host "Config file for $Clientname not found or invalid, generating new config file."
    new-item $ConfigFile -type file | Out-Null
    $ColHeaders | Out-File $ConfigFile
    $DomainName = Read-Host -Prompt "What is the client's Active Directory Domain Name?"
    switch (Read-Host "Are we using fat VMs? y/n") {
        y {$IsFatVM=$True}
        n {$IsFatVM=$False}
        Default {$IsFatVM=$false}
    }
    if (!$IsFatVM) {
    switch (Read-Host "Are we using MCS? y/n") {
        y {$IsMCS=$True}
        n {$IsMCS=$False}
        Default {$IsMCS=$false}
    }
}
# Not doing any domain manipulation in this version.
#    $WorkerOU = Read-Host -Prompt "Please enter the OU where VDAs reside."
    switch (Read-Host "Are we using UPM? y/n") {
        y {$IsUPM=$True}
        n {$IsUPM=$False}
        Default {$IsUPM=$false}
    }
    if ($UPM -eq $True) {
        $PathToUPM = Read-Host -Prompt "Please enter the path to the UPM store."
        If (!($PathToUPM.StartsWith("\\"))) {
            Write-Host "This is not a valid UNC Path, please enter a valid UNC Path."
            $PathToUPM = Read-Host -Prompt "Please enter the path to the UPM store."
        }
    }
    $BaseDDCName = Read-Host -Prompt "Please enter the base Delivery Controller server name."
    $BaseSFName = Read-Host -Prompt "Please enter the base StoreFront server name."
    $BaseVDAName = Read-Host -Prompt "Please enter the base VDA name."
    switch (Read-Host "Are we using Office 365 Click To Run? y/n") {
        y {$Office365C2R=$True}
        n {$Office365C2R=$False}
        Default {$Office365C2R=$false}
    }
    if ($Office365C2R) {
    $PathToSoftware = Read-Host -Prompt "Please enter the path to the software fileshare."
    If (!($PathToSoftware.StartsWith("\\"))) {
        Write-Host "This is not a valid UNC Path, please enter a valid UNC Path."
        $PathToSoftware = Read-Host -Prompt "Please enter the path to the software fileshare."
        }
    }
    switch (Read-Host "Are we using Server VDAs? y/n") {
        y {$IsServerVDA=$True}
        n {$IsServerVDA=$False}
        Default {$IsServerVDA=$True}
    }
    $SQLServer = Read-Host -Prompt "Please enter the SQL Server name."
    $Answers = "$ClientName, $DomainName, $IsFatVM, $IsMCS, $IsUPM, $PathToUPM, $BaseDDCName, $BaseSFName, $BaseVDAName, $Office365C2R, $PathToSoftware, $IsServerVDA, $SQLServer" 
    $Answers | Out-File $ConfigFile -Append
    Write-Host "Config file for $Clientname generated successfully."    
}

function DeliveryController {
    Add-PSSnapin Citrix.*
    
    Set-Location $ScriptDir
    Write-Host "Installing Citrix Delivery Controller."
    $ControllerMedia = "./Files/XenAppMedia/x64/XenDesktop Setup/"
    $ControllerArgs = "/Components Controller,Desktopstudio /Configure_firewall /noreboot"
    Set-Location $ControllerMedia
    Invoke-Expression "./XenDesktopServerSetup.exe $ControllerArgs"
    Set-Location $ScriptDir

# Start the Delivery Controller configuration
    Write-Host "Configuring Citrix Delivery Controller."

if ($DDC1 -contains $env:COMPUTERNAME) {
    Write-Host "This server is the first Delivery Controller ($env:COMPUTERNAME)."
    $DeliveryArgs = "-DatabaseServer $SQLServer -DatabaseName_Site $SiteDB -DatabaseName_Logging $LogDB -DatabaseName_Monitor $MonitDB -DatabaseUser $DBUser -DatabasePassword $DBPass -SiteName $SiteName -LicenseServer $LicenseServer"
    Invoke-Expression "./Scripts/Bretty/configure_xendesktop_site.ps1 $DeliveryArgs"
}
else {
    Write-Host "This server is the second Delivery Controller ($env:COMPUTERNAME)."
    Add-XDController -AdminAddress localhost -SiteControllerAddress $DDC1
    Set-BrokerSite -TrustRequestsSentToTheXmlServicePort $true
}

}

function StoreFront {
    Add-PSSnapin Citrix*
    Set-Location $ScriptDir
    $baseurl = "https://storefront.$DomainName"
    $Farmname = "$ClientName StoreFront"
    $Port = "443"
    $TransportType = "HTTPS"
    $sslRelayPort = "443"
    $DeliveryServers = "$DDC1,$DDC2"
    $LoadBalance = $true
    $FarmType = "XenDesktop"
    $FriendlyName = "$ClientName StoreFront"
    $SFPath = "/Citrix/Store"
    $SFPathWeb = "/Citrix/StoreWeb"
    $SFPathDA = "/Citrix/StoreDesktopAppliance"

# Install StoreFront

    Write-Host "Installing Citrix StoreFront."
    $StoreFrontMedia = "./Files/XenAppMedia/x64/XenDesktop Setup/"
    $StoreFrontArgs = "/Components StoreFront /Configure_firewall /noreboot"
    Set-Location = $StoreFrontMedia
    Invoke-Expression "./XenDesktopServerSetup.exe $StoreFrontArgs"
    Set-Location $ScriptDir

# Start the StoreFront configuration

    Write-Host "Configuring storefront on $env:COMPUTERNAME"

    import-module "C:\Program Files\Citrix\Receiver StoreFront\Scripts\ImportModules.ps1"

if ($SF1 -contains $env:COMPUTERNAME) {
    Write-Host "This server is the first StoreFront Server ($env:COMPUTERNAME)."
    Set-DSInitialConfiguration -hostBaseUrl $baseurl -farmName $Farmname -port $Port -transportType $TransportType -sslRelayPort $sslRelayPort -servers $DeliveryServers -loadBalance $LoadBalance -farmType $FarmType -StoreFriendlyName $FriendlyName -StoreVirtualPath $SFPath -WebReceiverVirtualPath $SFPathWeb -DesktopApplianceVirtualPath $SFPathDA
}
else {
    Write-Host "This server is the second StoreFront Server ($env:COMPUTERNAME)."

}

}

function VDA {
Set-Location $ScriptDir

# Install Office C2R if required
    if ($Office365C2R) {
        Write-Host "Installing Office 365 Click to Run Package."
        $OfficeXML | Out-File "./Files/Office/DefaultConfig.xml"
        Invoke-Expression "./Files/Office/setup.exe /download ./Files/Office/DefaultConfig.xml"
        Invoke-Expression "./Files/Office/setup.exe /configure ./Files/Office/DefaultConfig.xml"
    }

# VDA Config from Windows 10 Mega Script

Write-Host "Optimising VDA."

$MegaScriptLocation = "./Scripts/Windows10MegaScript/"
$MegaScriptArgs = "-RemoveAppX -VDI -ClearStart -IEDefault"

Set-Location $MegaScriptLocation

Invoke-Expression "./Windows10MegaScript.ps1 $MegaScriptArgs"

# Install VDA Software

Write-Host "Installing VDA software"

$VDALocation = "./Files/XenAppMedia/x64/XenDesktop Setup/"
$VDAArgs = "/components vda /controllers '$DDC1, $DDC2' /optimize /quiet /noreboot"

Set-Location $VDALocation

Invoke-Expression "./XenDesktopVDASetup.exe $VDAArgs"

Set-Location $ScriptDir

}

#####################################################################################
###################################### Execute ######################################
#####################################################################################
# Runs functions based on machine name

# Figure out which server we're running on

If ($env:COMPUTERNAME.StartsWith($BaseDDCName)) {
    Write-Host "Running on Delivery Controller Server $env:COMPUTERNAME"
    DeliveryController
}

If ($env:COMPUTERNAME.StartsWith($BaseSFName)) {
    Write-Host "Running on StoreFront Server $env:COMPUTERNAME"
    StoreFront
}

If ($env:COMPUTERNAME.StartsWith($BaseVDAName)) {
    Write-Host "Running on VDA $env:COMPUTERNAME"
    VDA
}

# Script Ends
Write-Host "Script Complete."

Stop-Transcript