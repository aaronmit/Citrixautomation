# Determine where to do the logging
$logPS = "C:\Windows\Temp\configure_storefront.log"

Write-Verbose "Setting Arguments" -Verbose
$StartDTM = (Get-Date)

Start-Transcript $LogPS

# Import the StoreFront SDK
import-module "C:\Program Files\Citrix\Receiver StoreFront\Scripts\ImportModules.ps1"

# Use New UI
$UseNewUI = "no"

# Set up Store Variables
$baseurl = "https://storefront.onfido.com"
$Farmname = "OnFido_Production_CCloud"
$Port = "443"
$TransportType = "HTTPS"
$sslRelayPort = "443"
$Servers = "citrixcc.onfido.com"
$LoadBalance = $true
$FarmType = "XenDesktop"
$FriendlyName = "OnFido"
$SFPath = "/Citrix/OnFido"
$SFPathWeb = "/Citrix/OnFidoWeb"
$SFPathDA = "/Citrix/OnFidoDesktopAppliance"
$SiteID = 1

# Define Gateway
#$GatewayAddress = "https://workspace.bretty.me.uk"

# Define Beacons
$InternalBeacon = "https://storefront.onfido.com"
$ExternalBeacon2 = "https://www.citrix.com"

# Define Trusted Domains
$AuthPath = "/Citrix/Authentication"
$Domain1 = "onfido.com"
$DefaultDomain = $Domain1

# Do the initial Config
Set-DSInitialConfiguration -hostBaseUrl $baseurl -farmName $Farmname -port $Port -transportType $TransportType -sslRelayPort $sslRelayPort -servers $Servers -loadBalance $LoadBalance -farmType $FarmType -StoreFriendlyName $FriendlyName -StoreVirtualPath $SFPath -WebReceiverVirtualPath $SFPathWeb -DesktopApplianceVirtualPath $SFPathDA

# Add beacon External (MAKE SURE TO ADD ANY EXTRA'S IN HERE)
Set-STFRoamingBeacon -internal $InternalBeacon -external $ExternalBeacon2

# Enable Unified Experience
$Store = Get-STFStoreService -siteID $SiteID -VirtualPath $SFPath
$Rfw = Get-STFWebReceiverService -SiteId $SiteID -VirtualPath $SFPathWeb
Set-STFStoreService -StoreService $Store -UnifiedReceiver $Rfw -Confirm:$False

# Set the Default Site
Set-STFWebReceiverService -WebReceiverService $Rfw -DefaultIISSite:$True

# Configure Trusted Domains
Set-STFExplicitCommonOptions -AuthenticationService $AuthService -Domains $Domain1,$Domain2 -DefaultDomain $DefaultDomain -HideDomainField $True -AllowUserPasswordChange Always -ShowPasswordExpiryWarning Windows

# Enable the authentication methods
#Enable-STFAuthenticationServiceProtocol -AuthenticationService $AuthService -Name Forms-Saml,Certificate

# Set Receiver for Web Auth Methods
Set-STFWebReceiverAuthenticationMethods -WebReceiverService $Rfw -AuthenticationMethods ExplicitForms,Certificate,CitrixAGBasic,Forms-Saml

# Set Receiver Deployment Methods
Set-STFWebReceiverPluginAssistant -WebReceiverService $Rfw -Html5Enabled Fallback -enabled $false

# Set Session Timeout Options
Set-STFWebReceiverService -WebReceiverService $Rfw -SessionStateTimeout 60
Set-STFWebReceiverAuthenticationManager -WebReceiverService $Rfw -LoginFormTimeout 30

# Set the Workspace Control Settings
Set-STFWebReceiverUserInterface -WebReceiverService $Rfw -WorkspaceControlLogoffAction "None"
Set-STFWebReceiverUserInterface -WebReceiverService $Rfw -WorkspaceControlEnabled $True
Set-STFWebReceiverUserInterface -WebReceiverService $Rfw -WorkspaceControlAutoReconnectAtLogon $False
Set-STFWebReceiverUserInterface -WebReceiverService $Rfw -WorkspaceControlShowReconnectButton $True
Set-STFWebReceiverUserInterface -WebReceiverService $Rfw -WorkspaceControlShowDisconnectButton $True

# Set Client Interface Settings
Set-STFWebReceiverUserInterface -WebReceiverService $Rfw -AutoLaunchDesktop $False
Set-STFWebReceiverUserInterface -WebReceiverService $Rfw -ReceiverConfigurationEnabled $True

# Enable Loopback on HTTP
Set-DSLoopback -SiteId $SiteID -VirtualPath $SFPathWeb -Loopback OnUsingHttp

Write-Verbose "Stop logging" -Verbose
$EndDTM = (Get-Date)
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalSeconds) Seconds" -Verbose
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalMinutes) Minutes" -Verbose
Stop-Transcript
