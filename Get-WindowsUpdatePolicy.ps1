<#
.Synopsis
   Get the Windows Update policy on local or remote computers via the registry.
.DESCRIPTION
   Get the Windows Update policy on local or remote computers via the registry.
   A Windows system can be configured to communicate with a managed update 
   environment such as WSUS, SCCM, or Intune. Get-WindowsUpdatePolicy will 
   query the registry keys that store the current Windows Update policy for a
   system. The function will also display if no policy is configured.
.NOTES
    Created by: Jason Wasser @wasserja
    Modified: 2/7/2017 01:40:26 PM  
.PARAMETER ComputerName
    Enter one or more computer names.
.PARAMETER Key
    The Windows Update policy registry key path is already specified.
.PARAMETER Credential
    Enter alternate credentials for accessing remote computers.
.EXAMPLE
   Get-WindowsUpdatePolicy

   Shows the current Windows Update policy of the local computer if it is configured.
.EXAMPLE
   Get-WindowsUpdatePolicy -ComputerName SERVER01,CLIENT02

   Shows the current Windows Update policy of server01 and client02 if it is configured.
.LINK
    https://gallery.technet.microsoft.com/scriptcenter/Get-WindowsUpdatePolicy-317c83d3
#>
function Get-WindowsUpdatePolicy
{
    [CmdletBinding()]
    [Alias()]
    [OutputType([Microsoft.Win32.RegistryKey])]
    Param
    (
        [Parameter(Mandatory=$false,
                   ValueFromPipeline=$true,
                   Position=0)]
        [string[]]$ComputerName=$env:COMPUTERNAME,

        # Windows Update policy registry key path
        [string]$Key='HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate',
        $Credential = [System.Management.Automation.PSCredential]::Empty
    )

    Begin
    {
        # Helper function to get the registry keys and values
        function Get-RegistryKey ($Key, $Computer) {
            Write-Verbose "$Computer"
            if (Test-Path $Key) {
                # Get the WindowsUpdate policy information
                Get-ItemProperty $Key
                
                # Get the WindowsUpdate AU sub key values
                if (Test-Path $Key\AU) {
                    Get-ItemProperty $Key\AU
                    }
                
                }
            else {
                Write-Host "No Windows Update policy set for $Computer."
                }
            }

    }
    Process
    {
        foreach ($Computer in $ComputerName) {
            if ($Computer -eq $env:COMPUTERNAME) {
                Write-Verbose "Getting Windows Update policy registry settings from $Computer."
                Get-RegistryKey -Key $Key
                }
            else {
                Write-Verbose "Getting remote Windows Update policy registry settings from $Computer."
                Invoke-Command -ScriptBlock ${function:Get-RegistryKey} -ComputerName $Computer -ArgumentList $Key,$Computer -Credential $Credential
                }
            }
    }
    End
    {
    }
}