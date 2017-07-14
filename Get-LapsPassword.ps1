<#
.SYNOPSIS
Get the local administrator password for a specified computer stored in Active Directory by LAPS.

.DESCRIPTION
Get the local administrator password for a specified computer stored in Active Directory by 
the Local Administrator Password Solution.

The LAPS tool periodically changes the local administrator account on a computer and stores the
password in an Active Directory attribute in the computer account.

.PARAMETER ComputerName
Enter a name of a computer

.PARAMETER AsSecureString
Optionally retrieve and convert the password to a secure string to be used with a 
credential object.

.PARAMETER IncludeLocalAdministratorAccount
Optionally include the logon name of the local administrator account.

.PARAMETER Credential
Optionally provide an alternate credential for accessing the privileged data from Active
Directory.

.EXAMPLE
Get-LapsPassword

ComputerName  LapsPassword
------------  ------------
COMPUTER01    35J3J2J3#2j

.EXAMPLE
Get-LapsPassword -ComputerName COMPUTER01,COMPUTER02,COMPUTER03

ComputerName  LapsPassword
------------  ------------
COMPUTER01    35J3J2J3#2j
COMPUTER02    DJEJ#F*&fX
COMPUTER03    ACCESS DENIED

.EXAMPLE
Get-LapsPassword -ComputerName COMPUTER01

ComputerName                  LapsPassword
------------                  ------------
COMPUTER01    System.Security.SecureString

.NOTES
Created by: Jason Wasser @wasserja
Modified: 7/14/2017 04:05:51 PM 

.LINK
https://technet.microsoft.com/en-us/mt227395.aspx
#>
#requires -modules ActiveDirectory
function Get-LapsPassword {
    [CmdletBinding()]
    param (
        [parameter(ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true)]
        [string[]]$ComputerName = $env:COMPUTERNAME,
        [switch]$AsSecureString,
        [switch]$IncludeLocalAdministratorAccountName,
        [System.Management.Automation.PSCredential]$Credential = [System.Management.Automation.PSCredential]::Empty
    )
    
    begin {
    }
    
    process {
        $ErrorActionPreference = 'Stop'
        $LapsPasswordAttributeName = 'ms-Mcs-AdmPwd'

        foreach ($Computer in $ComputerName) {
            try {

                # Gather local administrator account information if specified
                if ($IncludeLocalAdministratorAccountName) {
                    Write-Verbose -Message "Getting local administrator account information from $Computer"
                    try {
                        $LocalAdministratorAccount = $LocalAdministratorAccount = Get-WmiObject -ComputerName $Computer -Class Win32_UserAccount -Filter "LocalAccount='True' And Sid like '%-500'" -Credential $Credential
                        $LocalAdministratorAccountName = $LocalAdministratorAccount.Name
                    }
                    catch [System.UnauthorizedAccessException] {
                        Write-Warning -Message $_.Exception.Message
                        $LocalAdministratorAccountName = '-ACCESS DENIED-'
                    }
                    catch {
                        Write-Warning -Message $_.Exception.Message
                        $LocalAdministratorAccountName = '-UNKNOWN-'
                    }
                }


                # Gather LAPS password
                Write-Verbose -Message "Getting LAPS password information for $Computer"
                if ($Credential.UserName -ne $null) {
                    $ADComputer = Get-ADComputer -Identity $Computer -Properties $LapsPasswordAttributeName -Credential $Credential
                }
                else {
                    $ADComputer = Get-ADComputer -Identity $Computer -Properties $LapsPasswordAttributeName
                }
                
                if ($ADComputer.$LapsPasswordAttributeName) {
                    if ($AsSecureString) {
                        $LapsPassword = ConvertTo-SecureString -String $ADComputer.$LapsPasswordAttributeName -AsPlainText -Force
                    }
                    else {
                        $LapsPassword = $ADComputer.$LapsPasswordAttributeName
                    }
                }
                else {
                    $LapsPassword = '-ACCESS DENIED-'
                }
            
                
                $LapsPasswordProperties = [ordered]@{
                    ComputerName = $Computer
                    LapsPassword = $LapsPassword
                }
                if ($IncludeLocalAdministratorAccountName) {
                    $LapsPasswordProperties.Add('Username', $LocalAdministratorAccountName)
                }
                $LapsPassword = New-Object -TypeName PSCustomObject -Property $LapsPasswordProperties
                $LapsPassword

            }
            catch {
                Write-Error -Message $_.Exception.Message
            }
        }
    }
    
    end {
    }
}