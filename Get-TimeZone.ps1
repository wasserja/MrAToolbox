<#
.Synopsis
   This script retreives the timezone of a local or remote computer via WMI.
.DESCRIPTION
   This script retreives the timezone of a local or remote computer via WMI.
.NOTES
    Created by: Jason Wasser
    Modified: 9/11/2015 03:27:30 PM 

    Changelog:
     * Added credential support.
     * Simplified code as per suggestions from Jeffrey Hicks @JeffHicks
.EXAMPLE
   Get-TimeZone
   Shows the localhost timezone.
.EXAMPLE
   Get-TimeZone -ComputerName SERVER1
   Shows the timezone of SERVER1.
.EXAMPLE
   Get-TimeZone -ComputerName (Get-Content c:\temp\computerlist.txt)
   Shows the timezone of a list of computers.
.LINK
    https://gallery.technet.microsoft.com/scriptcenter/Get-TimeZone-PowerShell-4f1a34e6
#>
Function Get-TimeZone {
    [CmdletBinding()]
    [Alias()]
    Param
    (
        # Computer name
        [Alias('Name')]
        [Parameter(Mandatory=$false,
                    ValueFromPipeLine=$true,
                    ValueFromPipelineByPropertyName=$true,
                    Position=0)]
        [string[]]$ComputerName=$env:COMPUTERNAME,
        $Credential = [System.Management.Automation.PSCredential]::Empty
    )
    Begin
    {
    }
    Process
    {
        foreach ($Computer in $ComputerName) {
            try {
                $ServerInfo = Get-WmiObject -Class win32_timezone -ComputerName $Computer -ErrorAction Stop -Credential $Credential
                $cn = $ServerInfo.__SERVER
                $TimeZone = $ServerInfo.Caption
                }
            catch {
                $TimeZone = $_.Exception.Message 
                }
            finally {
                $propHash = @{
                    Computername = $Computer
                    TimeZone = $TimeZone
                }
                $objTimeZone = New-Object -type PSObject -Property $propHash
                $objTimeZone
                }
            }
    }
    End
    {
    }
}