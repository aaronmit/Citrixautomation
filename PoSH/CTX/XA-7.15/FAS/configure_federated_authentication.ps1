# Set FAS in Registry so deployment doesn't fail
$Computer = "$env:computername" + "$"
reg add HKLM\SOFTWARE\Policies\Citrix\Authentication\UserCredentialService\Addresses /f /v Address1 /t REG_SZ /d 'web.bretty.me.uk'
reg add HKLM\SOFTWARE\WOW6432Node\Policies\Citrix\Authentication\UserCredentialService\Addresses /f /v Address1 /t REG_SZ /d 'web.bretty.me.uk'
# Add Server to Enterprise Admin Group
ADD-ADGroupMember "Enterprise Admins" -members "$Computer"