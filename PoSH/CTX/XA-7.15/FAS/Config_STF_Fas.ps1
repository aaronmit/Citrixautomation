## DO NOT RUN - NOT ALIGNED

& "$Env:PROGRAMFILES\Citrix\Receiver StoreFront\Scripts\ImportModules.ps1"

$StoreVirtualPath = "/Citrix/Store"
$store = Get-STFStoreService -VirtualPath $StoreVirtualPath
$auth = Get-STFAuthenticationService -StoreService $store
Set-STFClaimsFactoryNames -AuthenticationService $auth -ClaimsFactoryName "FASClaimsFactory"
Set-STFStoreLaunchOptions -StoreService $store -VdaLogonDataProvider "FASLogonDataProvider"

$storeVirtualPath = "/Citrix/Store1" 
$auth = Get-STFAuthenticationService -Store (Get-STFStoreService -VirtualPath $storeVirtualPath) 
$spId = $auth.AuthenticationSettings["samlForms"].SamlSettings.ServiceProvider.Uri.AbsoluteUri 
$acs = New-Object System.Uri $auth.Routing.HostbaseUrl, ($auth.VirtualPath + "/SamlForms/AssertionConsumerService") 
$md = New-Object System.Uri $auth.Routing.HostbaseUrl, ($auth.VirtualPath + "/SamlForms/ServiceProvider/Metadata") 
$samlTest = New-Object System.Uri $auth.Routing.HostbaseUrl, ($auth.VirtualPath + "/SamlTest") 
Write-Host "SAML Service Provider information: 
Service Provider ID: $spId 
Assertion Consumer Service: $acs 
Metadata: $md 
Test Page: $samlTest" 

Get-Module "Citrix.StoreFront*" -ListAvailable | Import-Module 
# Remember to change this with the virtual path of your Store. 
$StoreVirtualPath = "/Citrix/Store" 
$store = Get-STFStoreService -VirtualPath $StoreVirtualPath 
$auth = Get-STFAuthenticationService -StoreService $store 
Update-STFSamlIdPFromMetadata -AuthenticationService $auth -FilePath "File path of the metadata file you downloaded from Okta" 