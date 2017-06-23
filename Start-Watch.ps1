<#
.SYNOPSIS
Watch a process in a loop for updated output.

.DESCRIPTION
Watch a process in a loop for updated output. This is an equivalent
of the linux watch command. 

.NOTES
Author: John Rizzo @johnrizzo1
Modified by: Jason Wasser @wasserja
Created: 6/12/2014
Modified: 5/19/2017 10:40:18 AM 

.EXAMPLE
Start-Watch -Interval 5 -Command 'netstat -an | Select-String :123'

Every 2s: netstat -an | Select-String :123      Friday, May 19, 2017 10:27:01 AM

UDP    0.0.0.0:123            *:*                    
UDP    [::]:123               *:*       

Watch netstat for port 123 access

.EXAMPLE
Start-Watch -Interval 5 -Command 'netstat -an | Select-String SYN'

Every 5s: netstat -an | Select-String SYN      Friday, May 19, 2017 10:41:45 AM

TCP    10.111.161.155:59105   172.17.55.13:3333       SYN_SENT
.EXAMPLE
Start-Watch -Interval 10 -Command 'Get-ChildItem -Path C:\Logs'

Watch a directory for new files.

.PARAMETER Interval
Interval in seconds that the command should be repeated.

.PARAMETER Command
The command that you want to repeat every $Interval seconds. 
The command MUST be wrapped in single or double quotes.

.LINK
http://johnrizzo.net/powershell-watch-script-command/

.LINK
http://mrautomaton.com
#>
function Start-Watch {
    [CmdletBinding(SupportsShouldProcess = $True, ConfirmImpact = 'High')]
    [Alias('watch')]
    param (
        [Parameter(Mandatory = $False,
            ValueFromPipeline = $True,
            ValueFromPipelineByPropertyName = $True)]
        [alias('n')]
        [int]$Interval = 10,

        [Parameter(Mandatory = $True,
            ValueFromPipeline = $True,
            ValueFromPipelineByPropertyName = $True)]
        [string]$Command
    )
    process {
        $cmd = [scriptblock]::Create($command)
        While ($True) {
            Clear-Host
            Write-Host "Every $Interval`s: $Command `t$(Get-Date -Format F) `n" -ForegroundColor Green
            $cmd.Invoke()
            Start-Sleep -Seconds $Interval
        }
    }
}