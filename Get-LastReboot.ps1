<#
.Synopsis
   Get-LastReboot scans the Event log of a local or remote computer for
   events with ID 1074.
.DESCRIPTION
   Get-LastReboot scans the Event log of a local or remote computer for
   events with ID 1074. 

   Created by: Jason Wasser
   Modified: 1/23/2015

   

.EXAMPLE
   Get-LastReboot
   Retrieves the reboot events from the local computer.
.EXAMPLE
   Get-LastReboot -computername server1,computer03
   Retrieves the reboot events from server1 and computer03.
#>
Function Get-LastReboot {
    [CmdletBinding()]
    [Alias()]
    [OutputType([int])]
    Param
    (
        # Computer name(s)
        [Parameter(Mandatory=$false,
                    ValueFromPipelineByPropertyName=$true,
                    Position=0)]
        [string[]]$ComputerName=$env:COMPUTERNAME,
        # Number of newest recent entries from the System log
        [Parameter(Mandatory=$false,Position=1)]
        [int]$Newest=1000
    )
    Begin
    {
    }
    Process
    {
        foreach ($Computer in $ComputerName) {
            Get-EventLog -LogName System -Newest $Newest -ComputerName $Computer | Where-Object {$_.eventid -eq '1074'} | Format-Table machinename, username, timegenerated -AutoSize
            }
    }
    End
    {
    }
}