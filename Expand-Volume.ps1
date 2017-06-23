<#
.Synopsis
   Expand a volume to fill out the available space.
.DESCRIPTION
   Expand a volume to fill out the available space.
.EXAMPLE
   Expand-Volume -ComputerName SERVER01 -DriveLetter D
   Expands the D: drive on SERVER01 to use all available free space.
#>
function Expand-Volume
{
    [CmdletBinding()]
    Param
    (
        # ComputerName
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [string[]]$ComputerName,

        # Drive Letter of the Volume to be expanded
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [string[]]$DriveLetter

    )

    Begin
    {
    }
    Process
    {
        foreach ($Computer in $ComputerName) {
            $CimSession = New-CimSession -Computername $Computer
            foreach ($Volume in $DriveLetter) {
                Resize-Partition -CimSession $CimSession -DriveLetter $Volume -Size (Get-PartitionSupportedSize -DriveLetter $Volume -CimSession $CimSession).sizeMax
                Get-Volume -CimSession $CimSession
                }
            Remove-CimSession -CimSession $CimSession
            }
    }
    End
    {
    }
}