<#
.Synopsis
   Gets a list of members in a particular local group.
.DESCRIPTION
   Gets a list of members in a particular local group.

.NOTES
   Created by: Jason Wasser @wasserja
   Modified: 4/3/2015 03:24:26 PM 
.EXAMPLE
   Get-LocalGroupMembership | Select-Object -ExpandProperty GroupMembers
   Lists the members of the Administrators group of the local computer.
.EXAMPLE
   Get-LocalGroupMembership -ComputerName SERVER01
   Lists the members of the Administrators group on SERVER01.
.EXAMPLE
   Get-LocalGroupMembership -ComputerName SERVER01,SERVER02 -Groups "Remote Desktop Users"
   Lists the members of the Remote Desktop Users group on SERVER01 and SERVER02.
#>
function Get-LocalGroupMembership
{
    [CmdletBinding()]
    #[OutputType([int])]
    Param
    (
        # ComputerName
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [string[]]$ComputerName=$env:COMPUTERNAME,

        # Group Name
        [Parameter(Mandatory=$false,
                    ValueFromPipelineByPropertyName=$true,
                    Position=1)]
        [string[]]$Groups="Administrators"
    )

    Begin
    {
    }
    Process
    {
        foreach ($Computer in $ComputerName) {
            #Write-Verbose 
            foreach ($Group in $Groups) {
                $LocalGroup = [ADSI]"WinNT://$Computer/$Group"
                $Members = @($LocalGroup.Invoke("Members")) | foreach { $_.GetType().InvokeMember("Name", 'GetProperty', $null, $_, $null) }
                $propHash = [ordered]@{
                    ComputerName = $ComputerName
                    GroupName = $Group
                    GroupMembers = $Members
                    }
                $GroupMembers = New-Object -type PSObject -Property $propHash
                $GroupMembers
                }
            }
    }
    End
    {
    }
}