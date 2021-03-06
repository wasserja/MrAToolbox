<#
.SYNOPSIS
Get-DiskInventory retrieves logical disk information from one or
more computers.
.DESCRIPTION
Get-DiskInventory uses WMI to retrieve the Win32_LogicalDisk
instances from one or more computers. It displays each disk's
drive letter, free space, used space, total size, and percentage of free
space.
.NOTES
Created by: Jason Wasser @wasserja
Modified: 1/10/2017 11:05:17 AM 
.PARAMETER ComputerName
The computer name, or names, to query. Default: Localhost.
.PARAMETER drivetype
The drive type to query. See Win32_LogicalDisk documentation
for values. 3 is a fixed disk, and is the default.
.EXAMPLE
Get-DiskInventory
Get the logical disk inventory from the local computer.
.EXAMPLE
Get-DiskInventory -ComputerName SERVER-R2
Get the logical disk inventory from the remote server SERVER-R2.
.LINK
https://gallery.technet.microsoft.com/scriptcenter/Get-DiskInventory-2d09f3f7
#>
function Get-DiskInventory
{
    [CmdletBinding()]
    [Alias()]
    Param
    (
        # ComputerName
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [string[]]$ComputerName=$env:COMPUTERNAME,

        # DriveType 3 is fixed disk (excludes USB Drives and CD ROM)
        [int]$DriveType=3
    )

    Begin
    {
    }
    Process
    {
        
        foreach ($Computer in $ComputerName) {
            Get-WmiObject -class Win32_LogicalDisk -computername $Computer `
            -filter "drivetype=$DriveType" |
            Sort-Object -property DeviceID |
            Select-Object -Property PSComputerName,DeviceID,VolumeName,
            @{l='FreeSpace(GB)';e={$_.FreeSpace / 1GB -as [int]}},
            @{l='Capacity(GB)';e={$_.Size / 1GB -as [int]}},
            @{l='UsedSpace(GB)';e={($_.Size - $_.FreeSpace) / 1GB -as [int]}},
            @{l='%Free';e={$_.FreeSpace / $_.Size * 100 -as [int]}}
            }

    }
    End
    {
    }
}