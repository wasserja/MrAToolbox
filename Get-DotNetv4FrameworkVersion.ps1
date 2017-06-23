<#
.SYNOPSIS
Gets the installed .NET Framework v4 version from the computer's registry.

.DESCRIPTION
Gets the installed .NET Framework v4 version from the computer's registry.

.NOTES 
Created by: Jason Wasser @wasserja
Modified: 6/21/2017 01:53:27 PM 

Changelog:
* Added support for .NET Framework 4.7

.PARAMETER ComputerName
Enter a computer name to check the .Net Framework 4 version installed.

.EXAMPLE
Get-DotNetFrameworkVersions -ComputerName server1
Retreives the .NET framework 4 version information from computer Server1.

.LINK

#>
function Get-DotNetv4FrameworkVersion {
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0)]
        [string[]]$ComputerName = $env:COMPUTERNAME
    )

    Begin {

    
        # Helper function to do the work of gathering the correct values from the registry.
        function Get-DotNetVersionfromRegistry {
            $DotNetv4FullKey = 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full'
            $DotNetv45VersionTable = @{
                '4.0.30319' = '.NET Framework 4';
                '378389'    = '.NET Framework 4.5';
                '378675'    = '.NET Framework 4.5.1';
                '378758'    = '.NET Framework 4.5.1';
                '379893'    = '.NET Framework 4.5.2';
                '393295'    = '.NET Framework 4.6';
                '393297'    = '.NET Framework 4.6';
                '394254'    = '.NET Framework 4.6.1';
                '394271'    = '.NET Framework 4.6.1';
                '394802'    = '.NET Framework 4.6.2';
                '394806'    = '.NET Framework 4.6.2';
                '460805'    = '.NET Framework 4.7'
            }    
        
            if (Test-Path $DotNetv4FullKey) {
                Write-Verbose '.Net Framework 4 Full registry Key Exists'
            
                # For versions of .NET Framework >= 4.5
                $DotNetv4FullReleaseNumber = (Get-Item $DotNetv4FullKey).GetValue('Release')
            
                if ($DotNetv4FullReleaseNumber) {
                    $DotNetv4FullReleaseNumber = $DotNetv4FullReleaseNumber.ToString()
                }
                else {
                    # For .NET framework version < 4.5
                    $DotNetv4FullReleaseNumber = (Get-Item $DotNetv4FullKey).GetValue('Version')
                }
            
            
                if ($DotNetv45VersionTable.($DotNetv4FullReleaseNumber).tostring()) {
                    Write-Verbose 'Found a valid .net 4 version'
                    $DotNetv4FullVersionName = $DotNetv45VersionTable.$DotNetv4FullReleaseNumber
                }
                else {
                    Write-Verbose 'Did not find a matching .net version release number.'
                    $DotNetv4FullVersionName = 'Unknown'
                }
                $DotNetv4VersionProperties = @{
                    ComputerName              = $env:COMPUTERNAME
                    DotNetv4FullVersionName   = $DotNetv4FullVersionName
                    DotNetv4FullReleaseNumber = $DotNetv4FullReleaseNumber
                }
                $DotNetv4FullVersion = New-Object -TypeName PSCustomObject -Property $DotNetv4VersionProperties
                $DotNetv4FullVersion
            }

            else {
                Write-Verbose '.Net Framework 4 Full registry key does not exist.'

                $DotNetv4VersionProperties = @{
                    ComputerName              = $env:COMPUTERNAME
                    DotNetv4FullVersionName   = 'Not Installed'
                    DotNetv4FullReleaseNumber = 'Not Installed'
                }
                $DotNetv4FullVersion = New-Object -TypeName PSCustomObject -Property $DotNetv4VersionProperties
                $DotNetv4FullVersion
            }
        }
    

    }
    Process {

        foreach ($Computer in $ComputerName) {
            Write-Verbose -Message "Checking .NET Framework 4 version on local computer $Computer"
            if ($Computer -eq $env:COMPUTERNAME) {
                Get-DotNetVersionfromRegistry
            }
            else {
                Write-Verbose -Message "Checking .NET Framework 4 version on remote computer $Computer"
                Invoke-Command -ComputerName $Computer -ScriptBlock ${function:Get-DotNetVersionfromRegistry}
            }
        }
    }
    End {
    }
}