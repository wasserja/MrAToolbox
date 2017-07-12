﻿<#
.SYNOPSIS
Get the time for when the local administrator account password was last set.

.DESCRIPTION
Get the time for when the local administrator account password was last set.

.PARAMETER ComputerName
Enter a computer name.

.PARAMETER Credential
Provide a credential for accessing remote computers.

.EXAMPLE
Get-LocalAdministratorPasswordLastSet

Username        : Administrator
ComputerName    : HONEYPOT1337
SID             : S-1-5-21-0000-0000000-500
FullName        : Workstation Admin
PasswordLastSet : 7/12/2017 1:02:41 PM

.EXAMPLE
Get-LocalAdministratorPasswordLastSet -ComputerName COLLATERAL01 -Credential (Get-Credential)

Username        : Administrator
ComputerName    : COLLATERAL01
SID             : S-1-5-21-0000-0000000-500
FullName        : Administrator
PasswordLastSet : 7/12/2017 1:02:41 PM

.NOTES
Created by: Jason Wasser @wasserja
Modified: 7/12/2017 01:05:19 PM 

I need to convert this to CIM and maybe find a better way to get the local user password other than ADSI. 
Get-LocalUser works, but I don't think that is available for older versions of OS and PowerShell

#>
function Get-LocalAdministratorPasswordLastSet {
    [CmdletBinding()]
    param (
        [string[]]$ComputerName = $env:COMPUTERNAME,
        [System.Management.Automation.PSCredential]$Credential = [System.Management.Automation.PSCredential]::Empty
    )
    begin {}
    process {
        foreach ($Computer in $ComputerName) {
            try {
                Write-Verbose -Message "Attempting to get local administrator account information on $Computer"
                $LocalAdministratorAccount = Get-WmiObject -Class Win32_UserAccount -Filter "LocalAccount='True' And Sid like '%-500'" -ComputerName $Computer -Credential $Credential -ErrorAction Stop
                $LocalAdministratorPasswordLastSetProperties = [ordered]@{
                    Username           = $LocalAdministratorAccount.Name
                    ComputerName       = $LocalAdministratorAccount.PSComputerName
                    PasswordLastSet    = (Get-Date).AddSeconds( -(([adsi]"WinNT://$Computer/$($LocalAdministratorAccount.Name),user").PasswordAge).Value)
                    SID                = $LocalAdministratorAccount.SID
                    FullName           = $LocalAdministratorAccount.FullName
                    Description        = $LocalAdministratorAccount.Description
                    Disabled           = $LocalAdministratorAccount.Disabled
                    AccountType        = $LocalAdministratorAccount.AccountType
                    PasswordChangeable = $LocalAdministratorAccount.PasswordChangeable
                    Lockout            = $LocalAdministratorAccount.Lockout
                }
                $LocalAdministratorPasswordLastSet = New-Object -TypeName PSCustomObject -Property $LocalAdministratorPasswordLastSetProperties
                $LocalAdministratorPasswordLastSet
            }
            catch [System.UnauthorizedAccessException] {
                Write-Error -Message "Access is denied to $Computer"
            }
            catch {
                Write-Error -Message "Unable to connect to $Computer"
            }
        
        }
    }
    end {}
}