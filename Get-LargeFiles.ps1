<#
.Synopsis
   Use PowerShell to get a report of the largest files in a directory.
.DESCRIPTION
   Use PowerShell to get a report of the largest files in a directory.
.NOTES
   Created by Jason Wasser
   Modified: 3/24/2015 01:24:03 PM 


.EXAMPLE
   Get-LargeFiles
   Outputs a list of the ten largest files in the current directory.
.EXAMPLE
   Get-LargeFiles -Path C:\Temp -Recurse
   Outputs a list of the ten largest files in c:\Temp and subfolders.
.EXAMPLE
   Get-LargeFiles -Path C:\Temp -Count 20 -Recurse -FormattedOutput
   Outputs a list of the twenty largest files in c:\Temp and subfolders
   with af friendly formatted output.
#>
Function Get-LargeFiles
{
    [CmdletBinding()]
    [Alias('glf')]
    [OutputType([System.IO.FileInfo])]
    Param
    (
        # The starting path, defaults to current directory.
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [string]$Path=".",

        # Count of files to display
        [Parameter(Mandatory=$false,Position=1)]
        [int]$Count=10,

        # Recurse switch
        [Parameter(Mandatory=$false,Position=2)]
        [switch]$Recurse=$false,

        # Formatted output boolean
        [Parameter(Mandatory=$false,Position=3)]
        [switch]$FormattedOutput=$false
    )

    Begin {}
    Process
    {
        if ($FormattedOutput) {
            Get-ChildItem $Path -Recurse:([bool]$Recurse.IsPresent) | Sort-Object -Property Length -Descending | Select-Object -First $Count -Property Name,@{Label="Size(MB)";Expression={$_.Length/1MB -as [int]}},FullName
            }
        else {
            Get-ChildItem $Path -Recurse:([bool]$Recurse.IsPresent) | Sort-Object -Property Length -Descending | Select-Object -First $Count
            }
    }
    End {}
}