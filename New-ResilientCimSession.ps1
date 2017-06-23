<#
.SYNOPSIS
Make a CimCession that attempts both protocols WSMAN and DCOM.

.DESCRIPTION
Make a CimCession that attempts both protocols WSMAN and DCOM.
The trusty Get-WmiObject cmdlet has been around since the early days of PowerShell, but
CIM is the successor to this cmdlet. While the Get-WmiObject cmdlet could only connect 
over DCOM ports, CIM can use the WSMAN protocol (PowerShell Remoting Protocol PSRP). The
New-ResilientCimSession is designed to establish a CIM session with one protocol 
(preferably WSMAN) and then fail over to the other protocol (DCOM).

.PARAMETER ComputerName
Enter a computername to which you need to establish a CIM session.

.PARAMETER Protocol
Provide the protocol to attempt first.

.PARAMETER Credential
Provide a credential object to use to establish the CIM session.

.EXAMPLE
$CimSession = New-ResilientCimSession -ComputerName SERVER01

.EXAMPLE
$CimSession = New-ResilientCimSession -ComputerName SERVER02 -Protocol Dcom -Credential (Get-Credential)

.NOTES
Created by: Jason Wasser @wasserja
Modified: 6/14/2017 01:26:38 PM 
.LINK
https://gallery.technet.microsoft.com/scriptcenter/Establish-CimSession-in-b2166b02
#>
function New-ResilientCimSession {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ComputerName,
        [ValidateSet('Wsman', 'Dcom')]
        [string]$Protocol = 'Wsman',
        [System.Management.Automation.PSCredential]$Credential = [System.Management.Automation.PSCredential]::Empty
    )

    begin {
        $ErrorActionPreference = 'Stop'

        function Test-CimSession {
            param (
                [string]$ComputerName,
                [string]$Protocol
            )
            $CimSessionOption = New-CimSessionOption -Protocol $Protocol
            try {
                Write-Verbose -Message  "Attempting to establish CimSession to $ComputerName using protocol $Protocol."
                if ($Credential.Username -eq $null) {
                    $CimSession = New-CimSession -ComputerName $ComputerName -SessionOption $CimSessionOption
                    Write-Verbose -Message "Successfully established CimSession $($CimSession.Name) to $ComputerName using protocol $Protocol."
                    $CimSession
                }
                else {
                    $CimSession = New-CimSession -ComputerName $ComputerName -SessionOption $CimSessionOption -Credential $Credential
                    Write-Verbose -Message "Successfully established CimSession $($CimSession.Name) to $ComputerName using protocol $Protocol."
                    $CimSession
                }
            }
            catch {
                Write-Verbose -Message  "Unable to establish CimSession to $ComputerName using protocol $Protocol."
            }
        }
    }
    process {

        $CimSession = Test-CimSession -ComputerName $ComputerName -Protocol $Protocol
        if ($CimSession) {
            $CimSession
        }
        else {
            if ($Protocol -eq 'Wsman') {
                $Protocol = 'Dcom'
            }
            else {
                $Protocol = 'Wsman'
            }
            $CimSession = Test-CimSession -ComputerName $ComputerName -Protocol $Protocol
            if ($CimSession) {
                $CimSession
            }
            else {
                Write-Error -Message "Unable to establish CimSession with any protocols."
            }
        }
    }
    end {}
}