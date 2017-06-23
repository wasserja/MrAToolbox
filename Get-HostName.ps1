<#
.Synopsis
   Get the hostname of a local or remote computer.
.DESCRIPTION
   Get the hostname of a local or remote computer. This can be used to 
   get the real hostname of computer that may have an alias.
.EXAMPLE
   Get-HostName -ComputerName ALIASSERVER
   Get the real hostname of the the aliasserver.
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
        [string[]]$ComputerName=$env:COMPUTERNAME
    )

    Begin
    {
    }
    Process
    {
        foreach ($Computer in $ComputerName) {
            try {
                $Hostname = Get-WmiObject -Class win32_operatingsystem -ComputerName $Computer -ErrorAction Stop | Select-Object -Property @{Label='Hostname';Expression={$_.PSComputerName}}
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