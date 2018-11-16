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
$baseurl = "https://workspace.bretty.me.uk"
$Farmname = "xd7x"
$Port = "443"
$TransportType = "HTTPS"
$sslRelayPort = "443"
$Servers = "xd.bretty.me.uk"
$LoadBalance = $true
$FarmType = "XenDesktop"
$FriendlyName = "Bretty"
$SFPath = "/Citrix/Bretty"
$SFPathWeb = "/Citrix/BrettyWeb"
$SFPathDA = "/Citrix/BrettyDesktopAppliance"
$SiteID = 1

# Define Gateway
$GatewayAddress = "https://workspace.bretty.me.uk"

# Define Beacons
$InternalBeacon = "https://workspaceac.bretty.me.uk"
$ExternalBeacon1 = "https://workspace.bretty.me.uk"
$ExternalBeacon2 = "https://www.citrix.com"

# Define NetScaler Variables
$GatewayName = "workspace.bretty.me.uk"
$staservers = "https://xd.bretty.me.uk/scripts/ctxsta.dll"
$CallBackURL = "https://workspacecb.bretty.me.uk"

# Define Trusted Domains
$AuthPath = "/Citrix/Authentication"
$Domain1 = "bretty.me.uk"
$Domain2 = "bretty.local"
$DefaultDomain = $Domain1

# Do the initial Config
Set-DSInitialConfiguration -hostBaseUrl $baseurl -farmName $Farmname -port $Port -transportType $TransportType -sslRelayPort $sslRelayPort -servers $Servers -loadBalance $LoadBalance -farmType $FarmType -StoreFriendlyName $FriendlyName -StoreVirtualPath $SFPath -WebReceiverVirtualPath $SFPathWeb -DesktopApplianceVirtualPath $SFPathDA

# Add NetScaler Gateway
$GatewayID = ([guid]::NewGuid()).ToString()
Add-DSGlobalV10Gateway -Id $GatewayID -Name $GatewayName -Address $GatewayAddress -CallbackUrl $CallBackURL -RequestTicketTwoSTA $false -Logon Domain -SessionReliability $true -SecureTicketAuthorityUrls $staservers -IsDefault $true

# Add Gateway to Store
$gateway = Get-DSGlobalGateway -GatewayId $GatewayID
$AuthService = Get-STFAuthenticationService -SiteID $SiteID -VirtualPath $AuthPath
Set-DSStoreGateways -SiteId $SiteID -VirtualPath $SFPath -Gateways $gateway
Set-DSStoreRemoteAccess -SiteId $SiteID -VirtualPath $SFPath -RemoteAccessType "StoresOnly"
Add-DSAuthenticationProtocolsDeployed -SiteId $SiteID -VirtualPath $AuthPath -Protocols CitrixAGBasic
Set-DSWebReceiverAuthenticationMethods -SiteId $SiteID -VirtualPath $SFPathWeb -AuthenticationMethods ExplicitForms,CitrixAGBasic
Enable-STFAuthenticationServiceProtocol -AuthenticationService $AuthService -Name CitrixAGBasic

# Add beacon External
Set-STFRoamingBeacon -internal $InternalBeacon -external $ExternalBeacon1,$ExternalBeacon2

# Enable Unified Experience
$Store = Get-STFStoreService -siteID $SiteID -VirtualPath $SFPath
$Rfw = Get-STFWebReceiverService -SiteId $SiteID -VirtualPath $SFPathWeb
Set-STFStoreService -StoreService $Store -UnifiedReceiver $Rfw -Confirm:$False

# Set the Default Site
Set-STFWebReceiverService -WebReceiverService $Rfw -DefaultIISSite:$True

# Configure Trusted Domains
Set-STFExplicitCommonOptions -AuthenticationService $AuthService -Domains $Domain1,$Domain2 -DefaultDomain $DefaultDomain -HideDomainField $True -AllowUserPasswordChange Always -ShowPasswordExpiryWarning Windows

# Enable the authentication methods
Enable-STFAuthenticationServiceProtocol -AuthenticationService $AuthService -Name Forms-Saml,Certificate

# Fully Delegate Cred Auth to NetScaler Gateway
Set-STFCitrixAGBasicOptions -AuthenticationService $AuthService -CredentialValidationMode Kerberos

# Create Featured App Groups
$FeaturedGroup = New-STFWebReceiverFeaturedAppGroup `
    -Title "IT Admin Apps" `
    -Description "IT Administration Applications" `
    -TileId appBundle1 `
    -ContentType AppName `
    -Contents "Citrix Studio","PVS Console"
Set-STFWebReceiverFeaturedAppGroups -WebReceiverService $Rfw -FeaturedAppGroup $FeaturedGroup

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

# Use New UI
If($UseNewUI -eq "yes"){
    Remove-Item -Path "C:\iNetPub\wwwroot\$SFPathWeb\receiver\css\*" -Recurse -Force
    Copy-Item -Path "\\bdt\mdtproduction$\Applications\Scripts\bretty\custom\storefront\workspace\receiver\*" -Destination "C:\iNetPub\wwwroot\$SFPathWeb\receiver" -Recurse -Force
    Copy-Item -Path "\\bdt\mdtproduction$\Applications\Scripts\bretty\custom\storefront\workspace\receiver.html" -Destination "C:\iNetPub\wwwroot\$SFPathWeb" -Recurse -Force
    Copy-Item -Path "\\bdt\mdtproduction$\Applications\Scripts\bretty\custom\storefront\workspace\receiver.appcache" -Destination "C:\iNetPub\wwwroot\$SFPathWeb" -Recurse -Force
    iisreset
}

# Copy down branding
Copy-Item -Path "\\bdt\mdtproduction$\Applications\Scripts\bretty\custom\storefront\branding\background.png" -Destination "C:\iNetPub\wwwroot\$SFPathWeb\custom" -Recurse -Force
Copy-Item -Path "\\bdt\mdtproduction$\Applications\Scripts\bretty\custom\storefront\branding\logo.png" -Destination "C:\iNetPub\wwwroot\$SFPathWeb\custom" -Recurse -Force
Copy-Item -Path "\\bdt\mdtproduction$\Applications\Scripts\bretty\custom\storefront\branding\hlogo.png" -Destination "C:\iNetPub\wwwroot\$SFPathWeb\custom" -Recurse -Force
Copy-Item -Path "\\bdt\mdtproduction$\Applications\Scripts\bretty\custom\storefront\branding\strings.en.js" -Destination "C:\iNetPub\wwwroot\$SFPathWeb\custom" -Recurse -Force
Copy-Item -Path "\\bdt\mdtproduction$\Applications\Scripts\bretty\custom\storefront\branding\style.css" -Destination "C:\iNetPub\wwwroot\$SFPathWeb\custom" -Recurse -Force

Write-Verbose "Stop logging" -Verbose
$EndDTM = (Get-Date)
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalSeconds) Seconds" -Verbose
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalMinutes) Minutes" -Verbose
Stop-Transcript