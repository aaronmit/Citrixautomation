# Metaphor IT (Ripped bits from Reddit etc)
# Core build of a server OS system
# Currently supports
# Windows Server 2016 STD

param([switch]$Elevated)
function Check-Admin {
$currentUser = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
$currentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}
if ((Check-Admin) -eq $false)  {
if ($elevated)
{
# could not elevate, quit
}
 
else {
 
Start-Process powershell.exe -Verb RunAs -ArgumentList ('-noprofile -noexit -file "{0}" -elevated' -f ($myinvocation.MyCommand.Definition))
}
exit
}

$folderkey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
$uackey = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System"
$iepath = "HKCU:\Software\Microsoft\Internet Explorer\Main\"
$AdminKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}"
$UserKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}"
$start_time = Get-Date
 
#Disables UAC
Set-ItemProperty $uackey ConsentPromptBehaviorAdmin 0
Set-ItemProperty $uackey ConsentPromptBehaviorUser 0
Set-ItemProperty $uackey EnableLUA 1
Set-ItemProperty $uackey PromptOnSecureDesktop 0

#Disable IE Enhanced Security
Set-ItemProperty -Path $AdminKey -Name "IsInstalled" -Value 0
Set-ItemProperty -Path $UserKey -Name "IsInstalled" -Value 0

#Changes folder options
Set-ItemProperty $folderkey Hidden 1
Set-ItemProperty $folderkey HideFileExt 0
Set-ItemProperty $folderkey AlwaysShowMenus 1
Set-ItemProperty $folderkey HideDrivesWithNoMedia 0
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\CabinetState" -Name "FullPath" -Value "1"
Stop-Process -processname explorer
 
#Changes power settings
powercfg /setactive 8C5E7fda-e8bf-4a96-9a85-a6e23a8c635c
powercfg /hibernate off
powercfg /change monitor-timeout-ac 0
powercfg /change monitor-timeout-dc 15
powercfg /change standby-timeout-ac 0
powercfg /change standby-timeout-dc 30
powercfg /change disk-timeout-ac 0
powercfg /change disk-timeout-dc 60

#Install RSAT tools
#Get-WindowsCapability -Name RSAT* -Online | Add-WindowsCapability -Online

#Starts Windows Update
Install-Module PSWindowsUpdate
Get-Command -Module PSWindowsUpdate
Add-WUServiceManager -ServiceID 7971f918-a847-4430-9279-4a52d1efe18d
Get-WUInstall –MicrosoftUpdate -Download -Install –AcceptAll –AutoReboot

#####TODO#####
#Create CSV with details of server (Version,hostname,IP,DHCP enabled)
#Could potentially then upload the CSV to an FTP server back at base?
#Convert this spaghetti code into functions and a parameters file
#Enable PS Remoting
#Enable WinRM
#Set NTP/Region
#Install Webroot/Labtech
#Disable local admin account, create new and generate random password
#Add computer into Server Manager pool (Especially with Core)