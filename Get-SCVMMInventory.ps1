<#
.Synopsis
   Get an inventory of VM's from System Center Virtual Machine Manager.
.DESCRIPTION
   Get an inventory of VM's from System Center Virtual Machine Manager
   including the vCPU's, memory, and total storage per VM. You can also
   get a summary of the total number of VM's, vCPU's, memory, and storage.
.NOTES
   Created by: Jason Wasser @wasserja
   Modified: 4/30/2015 03:41:39 PM 
.PARAMETER SCVMMServer
   Enter the name of the SCVMM server.
.PARAMETER ClusterName
   Enter the name(s) of the cluster.
.PARAMETER Summary
   Use the Summary switch to get a total summary of VM's for the cluster
   instead of a detailed list of VM's.
.PARAMETER ExcludeReplica
   By default the function excludes replica VM's. 
.EXAMPLE
   Get-SCVMMInventory -SCVMMServer tpascvmm01 -ClusterName tpacluster04
   Get a list of all the vm's on tpacluster04 with their cpu, memory
   and disk.
.EXAMPLE
   Get-SCVMMInventory -SCVMMServer tpascvmm01 -ClusterName tpacluster04 -Summary
   Get a total list of VM's, cpu, memory, and disk for cluster tpacluster04.
.EXAMPLE
   Get-SCVMMInventory -SCVMMServer tpascvmm01 -Summary
   Get a total list of VM's, cpu, memory, and disk for all clusters.
.EXAMPLE
   Get-SCVMMInventory -SCVMMServer tpascvmm01 -ClusterName tpacluster04 | Sort-Object -Property Name | Out-Gridview
   Get a list of all the vm's on tpacluster04 with their cpu, memory
   and disk sorted by VM name, displayed in gridview. 
.EXAMPLE
   Get-SCVMMInventory -SCVMMServer tpascvmm01 -Summary | Out-GridView
   Get a total list of VM's, cpu, memory, and disk for all clusters displayed in gridview.
.LINK
   
#>
#Requires -Modules virtualmachinemanager
function Get-SCVMMInventory {
    [CmdletBinding()]
    Param
    (
        # VMM Server Name
        [Parameter(Mandatory=$false,
                    ValueFromPipelineByPropertyName=$true,
                    Position=0)]
        $SCVMMServer='tpascvmm01',

        # Cluster Name(s)
        [Parameter(Mandatory=$false,
                    ValueFromPipelineByPropertyName=$true,
                    Position=1)]
        [string[]]$ClusterName,
        [switch]$Summary=$false,
        [bool]$ExcludeReplica=$true
    )
    Begin
    {
        # Establish connection to the VMM server
        $VMMServer = Get-SCVMMServer -ComputerName $SCVMMServer

        # Worker Function to do the inventory process
        function Start-Inventory {
            $SCVMHostCluster = Get-SCVMHostCluster -Name $Cluster -VMMServer $VMMServer
        
            foreach ($node in $SCVMHostCluster.Nodes) {
                if ($ExcludeReplica) {
                    $ClusterVMs += ($node.vms | Where-Object -FilterScript {$_.ReplicationStatus.ReplicationMode -ne 'Recovery'})
                    }
                else {
                    $ClusterVMs += $node.vms
                    }
                
                }
    
            if ($Summary) {
                $objTotalparms = [ordered]@{ 
                        ClusterName = $SCVMHostCluster.ClusterName
                        TotalVMs = $ClusterVMs.Count
                        TotalvCPUs = ($ClusterVMs | Measure-Object -Property CPUCount -Sum).Sum -as [int]
                        'TotalMemory(MB)' = ($ClusterVMs | Measure-Object -Property Memory -Sum).Sum -as [int]
                        'TotalStorage(GB)' = ($ClusterVMs | Measure-Object -Property TotalSize -Sum).Sum / 1GB -as [int]
                        }
                $objTotals = New-Object -TypeName PSObject -Property $objTotalparms
                Write-Output $objTotals
                }
            else {
                $ClusterVMs | Select-Object Name,CPUCount,Memory,@{n='TotalSize(GB)';e={$_.TotalSize / 1GB -as [int]}},VMHost
                }
            }
    }
    Process
    {
        # Initialize Variables
        $ClusterVMs = @()

        # If a specific cluster name(s) was provided.
        if ($ClusterName) {
            foreach ($Cluster in $ClusterName) {
                Start-Inventory
                }
            }
        # Else get all of the clusters registered to scvmm.
        else {
            $ClusterName = Get-SCVMHostCluster
            foreach ($Cluster in $ClusterName) {
                Start-Inventory
                }
            }
    }
    End
    {
    }
}