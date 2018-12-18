<#
.SYNOPSIS
Verify if a process is running or not.
.DESCRIPTION
Simple script to determine if a process is running or not.

.PARAMETER ProcessName
Enter the name of a process. ".exe" will automatically be removed.

.EXAMPLE
Test-Process -ProcessName notepad.exe

.NOTES
Created by: Jason Wasser @wasserja
Modified: 12/18/2018 04:51:04 PM 
#>
function Test-Process {
    [cmdletbinding()]
    param (
        [Parameter(ValueFromPipeline,ValueFromPipelineByPropertyName,Mandatory)]
        [string]$ProcessName
    )
    $ProcessName = $ProcessName -replace '.exe',''
    $Process = Get-Process -Name $ProcessName -ErrorAction SilentlyContinue
    if ($Process) {
        Write-Output $true
    }
    else {
        Write-Output $false
    }
}