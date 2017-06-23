<#
.SYNOPSIS
A function to execute commands at a future date and time.

.DESCRIPTION
Similar to the DOS AT command this PowerShell function allows
you to execute commands at a later time. This function does not
use scheduled tasks, but instead stays in a foreground process. 
Once the time for execution has occurred the foreground process
will execute the listed command.

.PARAMETER Time
Enter a date and time in the future.

.PARAMETER Command
Enter the command you want to execute at a future time. 
You may wish to wrap your command in single or double quotes so that
any special characters (i.e. '|') and not interpreted by the PowerShell
host. 

.EXAMPLE
at '3:00 PM' ping 8.8.8.8

.EXAMPLE
at '1/1/2020 00:00' Restart-Computer -Force

.NOTES
Created by: Jason Wasser @wasserja
Modified: 6/16/2017 04:03:55 PM 

.LINK
https://gallery.technet.microsoft.com/At-command-for-Powershell-db6df911
#>
function at {
    [cmdletbinding()]
    param (
        [Parameter(Mandatory = $true,
            Position = 0)]
        [ValidateScript( {$_ -gt (Get-Date)})]
        [datetime]$Time,
        
        [Parameter(Mandatory = $true,
            ValueFromRemainingArguments = $true)]
        [string]$Command
    )
    begin {}
    process {
        $VerbosePreference = 'Continue'
        $TimetoExecute = $Time - (Get-Date)
        Write-Verbose -Message "Executing $Command at $Time"
        Write-Verbose -Message "$($TimetoExecute.TotalSeconds -as [int]) seconds remaining."   
        Start-Sleep -Seconds $TimetoExecute.TotalSeconds
        Write-Verbose -Message "Timer expired. Executing $Command now $(Get-Date)"
        Invoke-Expression -Command $Command

    }    
    end {}    
}