<#
.SYNOPSIS
Function to email a specified log file.

.DESCRIPTION
This funtion is designed to email a log file to a user or distribution list.

.NOTES
Created by: Jason Wasser @wasserja
Modified: 6/23/2017 
Version 1.4
Changelog:
* Added authentication support with default of anonymous. Send-MailMessage 
    with Exchange forces authentication.
* Changed to use Send-MailMessage

.EXAMPLE
Send-Log -Path "C:\Logs\Reboot.log"
Sends the C:\Logs\Reboot.log to the recipient in the script parameters.
.EXAMPLE
Send-Log -Path c:\Logs\install.log -to admin@domain.com -from no-reply@domain.com -subject "See attached Log" -messagebody "See attached" -smtpserver smtp.domain.com
#>
function Send-Log {
    [CmdletBinding()]
    [OutputType([int])]
    Param
    (
        # Enter the path for the log file to be emailed.
        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0)]
        [Alias("Attachment", "LogPath")]
        $Path,
        [string]$SmtpServer = "smtp.domain.com",
        [string[]]$ToAddress = "it.distro@domain.com",
        [string]$FromAddress = "automaton@domain.com",
        [string]$Subject = "Automaton Alert $(get-date -Format "MM/dd/yyyy HH:mm")",
        [string]$MessageBody = "Please see attached.`n`nSincerely,`nYour friendly AutoMaton.",
        [int]$Port = 25,
        [System.Management.Automation.PSCredential]$Credential = [System.Management.Automation.PSCredential]::Empty
        
    )

    Begin {
    }
    Process {
        if (Test-Path $Path) {
            
            # Creating anonymous credential
            if ($Credential.Username -eq $null) {
                $SecurePassword = ConvertTo-SecureString -String 'anonymous' -AsPlainText -Force
                $Credential = New-Object System.Management.Automation.PSCredential('anonymous',$SecurePassword)
            }

            #Sending email 
            Write-Verbose "Sending $Path via SMTP."
            Send-MailMessage -To $ToAddress -From $FromAddress -Subject $Subject -Body $MessageBody -Attachments $Path -SmtpServer $smtpServer -Credential $Credential -Port $Port
        }
        else {
            Write-Error "Unable to find $Path."
        }
    }
    End {
    }
}