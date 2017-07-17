<#
.SYNOPSIS
Get the hostname of a local or remote computer.
.DESCRIPTION
Get the hostname of a local or remote computer. This can be used to 
get the real hostname of computer that may have an alias.
.EXAMPLE
Get-HostName -ComputerName ALIASSERVER
Get the real hostname of the the aliasserver.
.NOTES
Created By: Jason Wasser
Modified: 7/17/2017 08:59:48 AM 

* added credential support
#>
function Get-Hostname
{
    [CmdletBinding()]
    [Alias()]
    [OutputType([int])]
    Param
    (
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [string[]]$ComputerName=$env:COMPUTERNAME,
        [System.Management.Automation.PSCredential]$Credential = [System.Management.Automation.PSCredential]::Empty
    )

    Begin
    {
    }
    Process
    {
        foreach ($Computer in $ComputerName) {
            try {
                $Hostname = Get-WmiObject -Class win32_operatingsystem -ComputerName $Computer -Credential $Credential -ErrorAction Stop | Select-Object -Property @{Label='Hostname';Expression={$_.PSComputerName}}
                $Hostname
                }
            catch {
                Write-Error "Unable to get the hostname of $Computer."
                }
            }
    }
    End
    {
    }
}