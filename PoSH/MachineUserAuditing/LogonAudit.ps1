
$auditdir = "\\win103\exported$\$env:UserName\$env:ComputerName"
$dirtest = test-path -path $AuditDir
$regloc = "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Windows Messaging Subsystem"

Function Get-RegistryKeyPropertiesAndValues
{

 Param(
  [Parameter(Mandatory=$true)]
  [string]$path
  )

  Push-Location
  Set-Location -Path $path
  Get-Item . |
  Select-Object -ExpandProperty property |
  ForEach-Object {
      New-Object psobject -Property @{"Folder"=$_;
        "RedirectedLocation" = (Get-ItemProperty -Path . -Name $_).$_}}
  Pop-Location
}

if(!($dirtest )){
   New-Item -ItemType directory -Path $auditdir

get-psdrive -PSProvider FileSystem | select Name,Root,DisplayRoot | export-csv $auditdir\Drives.csv

write-host $env:userprofile

$Profilepath = [regex]::Escape($env:USERPROFILE)

$RedirectedFolders = Get-RegistryKeyPropertiesAndValues -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" | Where-Object {$_.RedirectedLocation -notmatch "$Profilepath"}
if ($RedirectedFolders -eq $null) {
    Write-Output "Folders are local" | out-file $auditdir\UserNotRedirected.txt
} else {
    $RedirectedFolders | format-list * | out-file $auditdir\Redirected.txt
}

reg export "HKCU\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Windows Messaging Subsystem" $auditdir\OutlookProfile.reg
Get-WMIObject -Class Win32_UserProfile | where {($_.LocalPath -eq $env:userprofile)} | select LocalPath,roamingpath,status | export-csv $auditdir\ProfilePath.csv

}