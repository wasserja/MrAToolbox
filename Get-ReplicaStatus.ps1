<#
.Synopsis
   Get the Hyper-V replica status of a Hyper-V server.
.DESCRIPTION
   Long description
.NOTES
   Created by: Jason Wasser
   Modified: 3/2/2015 02:37:31 PM 

   From: http://blogs.technet.com/b/enterprise_admin/archive/2013/12/17/hyper-v-replica-basic-monitoring-report.aspx
.EXAMPLE
   Get-ReplicaStatus
   Reports the Hyper-V Replica status from the local machine.
.EXAMPLE
   Get-ReplicaStatus -ComputerName SERVER01
   Reports the Hyper-V Replica status from SERVER01.
.EXAMPLE
   Get-ReplicaStatus -ComputerName (Get-Content c:\temp\serverlist.txt)
   Reports the Hyper-V Replica status from a list of computers in c:\temp\serverlist.txt.
#>
#Requires -Modules Hyper-V
function Get-ReplicaStatus
{
    [CmdletBinding()]
    [OutputType([int])]
    Param
    (
        # ComputerName
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
            Write-Verbose "Checking $Computer"
            $VMs = Get-VM -ComputerName $Computer | Where-Object {$_.replicationstate -notmatch "Disabled"} | Get-VMReplication
            $VMs | Select-Object -Property Name, PrimaryServer, ReplicaServer, ReplicationMode, State, ReplicationHealth, @{Expression={"{0:0.0}" -f ($_.FrequencySec / 60)};Label="Target Freq (min)"}, @{Expression={"{0:N0}" -f ((get-date)-($_.lastreplicationtime)).TotalMinutes};Label="Delta (min)"}
            }
    }
    End
    {
    }
}