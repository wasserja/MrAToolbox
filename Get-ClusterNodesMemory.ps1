<#
.Synopsis
   Get the available memory of each node in a cluster.
.DESCRIPTION
   Get the available memory of each node in a cluster particularly for Hyper-V.
.NOTES
   Created by: Jason Wasser
   Modified: 3/3/2015 09:16:21 AM 
   
   Version: 1.0
   Changelog
    * Changed format-table to select to work with pipeline.

    TODO:
     * Add error handling for getting the clusternodes.
.EXAMPLE
   Get-ClusterNodesMemory -ClusterName prodcluster01
.EXAMPLE
   Get-ClusterNodesMemory -ClusterNode prodcluster01,prodcluster02
#>
#Requires -Modules FailoverClusters
function Get-ClusterNodesMemory
{
    [CmdletBinding()]
    [Alias()]
    [OutputType([int])]
    Param
    (
        [Parameter(Mandatory=$true,Position=0)]
        [string[]]$ClusterName
    )

    Begin
    {
    }
    Process {
        foreach ($Cluster in $ClusterName) {
            $ClusterNodes = Get-ClusterNode -Cluster $Cluster | Where-Object {$_.State -ne "Down"}
            $MemoryStatistics = Get-WmiObject win32_operatingsystem -ComputerName $ClusterNodes | Sort-Object -Property FreePhysicalMemory -Descending | Select @{l='ComputerName';e={$_.__SERVER}},@{l='Free Memory(GB)';e={$_.FreePhysicalMemory / 1MB -as [int]}},@{l='Total Memory(GB)';e={$_.TotalVisibleMemorySize / 1MB -as [int]}}
            $MemoryStatistics
            }
        }
    End
    {
    }
}