##########################################
############### Jo Burgess ###############
############### 28/02/2019 ###############
##########################################

# Script to base build a server for deployment automation

############# Tasks ##############

# Set Machine Name
# Set Static IP
# Join Domain
# Enable PSRemoting
# Enable RSAT windows features

##################################

#Requires -RunAsAdministrator

param (
    [switch]$Prepare,
    [switch]$Logged,
    [switch]$ADAdminUser,
    [switch]$LocalAdminUser,
    [string]$ComputerName,
    [string]$DNSServer,
    [string]$IPAddress,
    [string]$IPSubnet,
    [string]$IPGateway,
    [string]$ADDomain,
    [switch]$LabTech
)

function Prepare {
    Write-Host "$now - Preparing $env:COMPUTERNAME setup script."
    
    New-Item $ADCredentialFile -Type File
    Read-Host "Enter Password for $ADAdminUser" -AsSecureString |  ConvertFrom-SecureString | Out-File "$ADcredentialfile"
    
    New-Item $LocalCredentialFile -Type File
    Read-Host "Enter Password for Local Admin User - $LocalAdminUser" -AsSecureString |  ConvertFrom-SecureString | Out-File "$Localcredentialfile"
}

function SetComputerName {
    if ($env:COMPUTERNAME -ne $ComputerName) {
        $localadminpass = Get-Content "$Localcredentialfile" | ConvertTo-SecureString
        $LocalCredential = New-Object System.Management.Automation.PSCredential($LocalAdminUser,$LocalAdminPass)
        Rename-Computer -NewName $ComputerName -LocalCredential $LocalCredential
        Write-Host "$now - Set Computer name to $Computername."
    }
}

function StaticIP {
    # If statment validates the configuration for the IP address to avoid setting the wrong thing
    if ((!$IPaddress) -and (!$IPGateway) -and (($IPSubnet -gt 0) -and ($IPSubnet -lt 33))) {
        
        # Get the interface which is using DHCP and set it to the static IP address defined in the parameters.
        get-netipaddress -AddressFamily ipv4 -PrefixOrigin dhcp | New-NetIPAddress -InterfaceAlias $_.interfacealias -IPAddress $IPaddress -DefaultGateway $IPGateway -PrefixLength $IPSubnet | Set-DnsClientServerAddress -interfacealias $_.interfacealias

        Write-Host "$now - Static IP set to the following"
        Write-Host "$now - IP Address:  $IPAddress"
        Write-Host "$now - Subnet:      $IPSubnet"
        Write-Host "$now - Gateway:     $IPGateway"
        Write-Host "$now - DNS Server:  $DNSServer"
        Write-Host "$now - IP Configuration Complete."
    }

    else {
        Write-Error -message "$now - Static IP address not set. No IP parameters declared or subnet in incorrect format."
        Write-Host "$now - IP Address:  $IPAddress"
        Write-Host "$now - Subnet:      $IPSubnet"
        Write-Host "$now - Gateway:     $IPGateway"
        Write-Host "$now - IP Configuration Aborted."
    }
    
}

function JoinDomain {
    if (($null -ne $env:userdnsdomain) -and ($ADDomain -ne $env:userdnsdomain)) {
        $ADadminpass = Get-Content "$ADcredentialfile" | ConvertTo-SecureString
        $ADCredential = New-Object System.Management.Automation.PSCredential($ADAdminUser,$ADAdminPass)
        Add-Computer -DomainName $ADDomain -Credential $ADCredential
        Write-Host "$now - Joined local computer ($env:COMPUTERNAME) to the domain $ADDomain."
    }
}

function Summary {
    # Creates a summary file containing details of what has been done
    $SummaryFile = ".\Summary - $ComputerName on $ADDomain.txt"
    Write-Host "Script run with the following parameters:" | Out-File "$SummaryFile" -Append
    Write-Host "IP Address:  $IPAddress" | Out-File "$SummaryFile" -Append
    Write-Host "Subnet:      $IPSubnet" | Out-File "$SummaryFile" -Append
    Write-Host "Gateway:     $IPGateway" | Out-File "$SummaryFile" -Append
    Write-host "Script completed at $now" | Out-File "$SummaryFile" -Append
    $OSInfo = Get-ComputerInfo
    Write-Host "OS:           $OSInfo.WindowsProductName" | Out-File "$SummaryFile" -Append
    Write-Host "Edition:      $OSInfo.WindowsEditionId" | Out-File "$SummaryFile" -Append
    Write-Host "Patch Level:  $OSInfo.WindowsVersion" | Out-File "$SummaryFile" -Append
}

function InstallLabtech {
    If ($LabTech) {
        if (test-path ".\agent_install.exe") {
            Start-Process -filepath ".\agentinstall.exe" -ArgumentList "/silent /NOREBOOT"
        }
    }
}

# Sets up the log file if the -logged parameter is set (this is the default)
if ($Logged) {
    New-Item -Path ".\$now - $env:COMPUTERNAME" -ItemType File
    Start-Transcript -Path ".\$now - $env:COMPUTERNAME" -Append -NoClobber -Force
}

workflow New-ComputerSetup {
        
    ##################################
    ####### Execute Functions ########
    ##################################

    # Set the Computer Name
    SetComputerName
    Checkpoint-Workflow
    
    # Set static IP
    StaticIP
    Checkpoint-Workflow
    
    # Join the Domain
    JoinDomain
    Checkpoint-Workflow
    
    ##################################
    ######## Standard Config #########
    ##################################

    # Enable PS Remoting
    Enable-PSRemoting
    Set-Service WinRM -StartMode Automatic
    Set-Item WSMan:localhost\client\trustedhosts -value *
    Write-host "$now - PowerShell Remoting enabled."
    Checkpoint-Workflow
    Restart-Computer

    # Install Remote Server Admin Tools
    Install-WindowsFeature -IncludeAllSubFeature RSAT
    Write-host "$now - Installed Remote Server Administration Tools."
    Checkpoint-Workflow
    Restart-Computer

    # Install Labtech
    InstallLabtech
    Checkpoint-Workflow
    Restart-Computer

    ##################################
    ######### Finish Script ##########
    ##################################

    Summary

        if ($logged) {
            Stop-Transcript
        }
}

##########################################
##########################################
############## Script Begins #############
##########################################
##########################################

# General setup

# Timestamp
$now = Get-Date -format g

# Names the credential files for local and AD accounts.
$ADCredentialFile = ".\$ADAdminUser"
$LocalCredentialFile = ".\$LocalAdminUser"

# Default Local Admin username to "Administrator" if no name specified.
If (!$LocalAdminUser) {
    $LocalAdminUser = "Administrator"
}

##################################
##### Prepare Script for Use #####
##################################

# If the script doesn't find credentials, it won't run. 
# This section asks for credentials for the local machine and the AD Domain.
if ($prepare -or (!$ADCredentialFile) -or (!$LocalCredentialFile)) {
    Prepare
}

##################################
########### EXECUTION ############
##################################

else {

    $JobName = "PSWorkflow"

    # Create the scheduled task
    $AtStartup = New-JobTrigger -AtStartup
    Register-ScheduledJob -Name ResumeWorkflow -Trigger $AtStartup -ScriptBlock {Import-Module PSWorkflow; Get-Job $JobName -State Suspended | Resume-Job}
    New-ComputerSetup -JobName $JobName
    Unregister-ScheduledJob -Name $JobName

}

Restart-Computer