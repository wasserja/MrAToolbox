<#
.Synopsis
   Start a remote desktop connection to a computer.
.DESCRIPTION
   Start a remote desktop connection to a computer. The function waits
   for the remote computer to be available on the specified TCP port 
   (default 3389). If the computer is online right now it connects
   immediately. If the computer is not responding to RDP, it waits until
   the computer responds. This is useful for those times you restart a
   computer and need to automatically reconnect once the computer is 
   online again.
.NOTES
  Created by: Jason Wasser
  Modified: 4/22/2015 10:41:00 AM 
.PARAMETER ComputerName
   The computer name to which you wish to connect.
.PARAMETER Port
   The TCP port of the remote desktop connection. Default 3389.
.PARAMETER AdditionalParameters
   Any additional mstsc.exe parameters such as /admin and /f. See
   mstsc.exe /? for additional parameters.
.PARAMETER Wait
   Wait for the computer to stop responding first before starting to 
   connect.
.EXAMPLE
   Connect-RemoteDesktop -ComputerName SERVER01
   Starts a remote desktop connection to SERVER01.
.EXAMPLE
   Connect-RemoteDesktop -ComputerName SERVER01 -Wait
   Starts a remote desktop connection to SERVER01 and wait for it to 
   stop responding (i.e. finish shutting down and restart.)
#>
#Requires -Version 4.0
function Connect-RemoteDesktop
{
    [CmdletBinding()]
    Param
    (
        # ComputerName
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [string]$ComputerName,

        # TCP port for Remote Desktop
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=1)]
        [int]$Port=3389,

        [string]$AdditionalParameters,

        # Wait for the computer to stop responding first and then connect
        [switch]$Wait
    )

    Begin
    {
        Function WaitForConnection {
            Write-Verbose "Waiting For Connection"
            while (-not $ConnectionTest.TcpTestSucceeded) {
                # Check DNS
                if ($ConnectionTest.NameResolutionSucceeded) {
                    if ($ConnectionTest.PingSucceeded) {
                        # Couldn't connect tcp, DNS is good, and ping is good. Let's .wait
                        Write-Verbose "$ComputerName is responding to ping, but not to TCP Port $Port. Retry in 5 seconds."
                        Start-Sleep -Seconds 5
                        }
                    else {
                        # Couldn't connect tcp, DNS is good, but no ping. Let's wait.
                        Write-Verbose "$ComputerName is not responding to ping. Retry in 5 seconds."
                        Start-Sleep -Seconds 5
                        }
                    }
                else {
                    Write-Error "Unable to resolve $ComputerName."
                    Return
                    }
                $ConnectionTest = Test-NetConnection -ComputerName $ComputerName -Port $Port
                }
            }
    }
    Process
    {
        # Initial connection test
        $ConnectionTest = Test-NetConnection -ComputerName $ComputerName -Port $Port
        
        # If the -Wait switch was provided and the computer is still connecting
        # we will wait for the computer to stop responding and then wait for it
        # to come back online.
        if ($Wait -and $ConnectionTest.TcpTestSucceeded) {
            # If we just restarted a computer we want to wait until it becomes unavailable
            # and then wait for it to be come available again.
            while ($ConnectionTest.TcpTestSucceeded) {
                # Wait
                Write-Verbose "-Wait option selected. Waiting for computer to stop responding first (i.e. restart)."
                Write-Output "$ComputerName still responding. Retry in 15 seconds."
                Start-Sleep -Seconds 15
                $ConnectionTest = Test-NetConnection -ComputerName $ComputerName -Port $Port
                }
            WaitForConnection
            
            # Execute mstsc
            Write-Verbose "Connecting to $ComputerName now."
            Invoke-Expression "mstsc /v $($ComputerName):$($Port) $($AdditionalParameters)"
            }
        # If the initial connection succeeded go ahead and connect.
        elseif ($ConnectionTest.TcpTestSucceeded) {
            # Execute mstsc
            Write-Verbose "Connecting to $ComputerName now."
            Invoke-Expression "mstsc /v $($ComputerName):$($Port) $($AdditionalParameters)"
            }
        else {
            WaitForConnection
            
            # Execute mstsc
            Write-Verbose "Connecting to $ComputerName now."
            Invoke-Expression "mstsc /v $($ComputerName):$($Port) $($AdditionalParameters)"
            }

    }
    End
    {
    }
}