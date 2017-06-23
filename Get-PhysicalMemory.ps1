<#
.SYNOPSIS
Get the total, used, and free physical memory of a local or remote computer.

.DESCRIPTION
Get the total, used, and free physical memory of a local or remote computer.

.NOTES
Created by: Jason Wasser
Modified: 1/30/2015
Version 1.0

.EXAMPLE
Get-PhysicalMemory
Get the physical memory of the localhost.

.EXAMPLE
Get-PhysicalMemory -ComputerName SERVER3
Get the physical memory of SERVER3

.EXAMPLE
Get-PhysicalMemory -BaseUnit MB
Get the physical memory in Megabytes.
#>
function Get-PhysicalMemory
{
    [CmdletBinding()]
    [Alias('Get-RAM')]
    Param
    (
        # ComputerName
        [Alias("name")]
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [string[]]$ComputerName=$env:COMPUTERNAME,
        [Parameter(Mandatory=$false)]
        [ValidateSet("MB","GB")]
        [string]$BaseUnit="GB"

    )

    Begin
    {
    }
    Process
    {
        foreach ($Computer in $ComputerName) {
            if ($BaseUnit -eq "MB") {
                Get-WmiObject -Class win32_operatingsystem -ComputerName $Computer | Format-Table -Property PSComputerName,@{name="TotalPhysicalMemory(MB)";e={$_.TotalVisibleMemorySize}},@{name='UsedPhysicalMemory(MB)';e={($_.TotalVisibleMemorySize - $_.FreePhysicalMemory)}},@{name='FreePhysicalMemory(MB)';e={$_.FreePhysicalMemory}} -AutoSize
                }
            elseif ($BaseUnit -eq "GB") {
                Get-WmiObject -Class win32_operatingsystem -ComputerName $Computer | Format-Table -Property @{name='ComputerName';e={$_.PSComputerName}},@{name="TotalPhysicalMemory(GB)";e={"{0:N2}" -f ($_.TotalVisibleMemorySize / 1MB)}},@{name='UsedPhysicalMemory(GB)';e={"{0:N2}" -f (($_.TotalVisibleMemorySize - $_.FreePhysicalMemory) / 1MB) }},@{name='FreePhysicalMemory(GB)';e={"{0:N2}" -f ($_.FreePhysicalMemory / 1MB)}} -AutoSize
                }
            else {
                Write-Error "Invalid BaseUnit $BaseUnit."
                }
            }
    }
    End
    {
    }
}