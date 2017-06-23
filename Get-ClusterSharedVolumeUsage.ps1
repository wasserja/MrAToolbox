<#
.Synopsis
   This script will list the Cluster Shared Volumess name, path, used space, 
   free space, size, percent free, owner node, and state.
.DESCRIPTION
   Using the Failover Clusters module this script will gather the cluster
   shared volume information and output them as a custom object which can then be
   piped to other cmdlets. The script defaults to check the cluster on localhost. 
.NOTES
   By: Jason Wasser
   Modified: 3/25/2015 02:30:47 PM 
.EXAMPLE
   Get-ClusterSharedVolumeUsage -ClusterName mycluster
   This example lists all the Cluster Shared Volumes.
.EXAMPLE
   Get-ClusterSharedVolumeUsage -ClusterName mycluster | Where-object {$_.name -like "*LUN33*"}
   This example lists any cluster shared volumes that have LUN33 in their name.
.EXAMPLE
   Get-ClusterSharedVolumeUsage -ClusterName mycluster | where-object {$_.path -like "*S3896*"}
   This example lists any cluster shared volumes whose file system path includes S3896.
.EXAMPLE
   Get-ClusterSharedVolumeUsage -ClusterName mycluster | Format-Table Name,UsedSpace,FreeSpace -AutoSize
   Display the cluster shared volumes in a table showing only Name, Used Space, and Free Space.
.EXAMPLE
   Get-ClusterSharedVolumeUsage -ClusterName mycluster1,mycluster2 | Out-GridView
   Display the cluster shared volumes for clusters mycluster1 and mycluster2 in a Grid View.
#>
#Requires -Modules FailoverClusters
Function Get-ClusterSharedVolumeUsage {
    param (
        [Parameter(Mandatory=$false,Position=0)]
        [string[]]$ClusterName=$env:COMPUTERNAME
        )

    Begin
    {
    }

    Process
    {
        foreach ($Cluster in $ClusterName) {
        
            $objs = @()
            $csvs = Get-ClusterSharedVolume -Cluster $Cluster
            foreach ( $csv in $csvs ) {
                $csvinfos = $csv | select -Property Name -ExpandProperty SharedVolumeInfo
                foreach ( $csvinfo in $csvinfos ) {
                    $obj = New-Object PSObject -Property ([ordered]@{
                        Name        = $csv.Name
                        Path        = $csvinfo.FriendlyVolumeName
                        Size        = $csvinfo.Partition.Size / 1gb -as [int]
                        FreeSpace   = $csvinfo.Partition.FreeSpace / 1gb -as [int]
                        UsedSpace   = $csvinfo.Partition.UsedSpace / 1gb -as [int]
                        PercentFree = $csvinfo.Partition.PercentFree -as [int]
                        OwnerNode   = $csv.OwnerNode
                        State       = $csv.State
                    })
                    $objs += $obj
                    }
                }
            $objs
            }
        }
    End {}
    }