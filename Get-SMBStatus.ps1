<#
.Synopsis
Determine if SMB client and server protocols are enabled or disabled.
.DESCRIPTION
Determine if SMB client and server protocols are enabled or disabled.
.NOTES
Created by: Jason Wasser @wasserja
Modified: 6/6/2017 09:22:38 AM 
.PARAMETER ComputerName
Enter a computer name or list of computer names to check SMB status.
.PARAMETER Credential
Provide a PScredential object to access the remote computer.
.EXAMPLE
Get-SMBStatus -ComputerName SERVER01

ComputerName     : SERVER01
SMB1ServerStatus : Disabled
SMB2ServerStatus : Enabled
SMB3ServerStatus : Enabled
SMB1ClientStatus : Disabled

.EXAMPLE
Get-SMBStatus -ComputerName server02 -Credential $Credential

ComputerName     : SERVER02
SMB1ServerStatus : Disabled
SMB2ServerStatus : Enabled
SMB3ServerStatus : Unsupported
SMB1ClientStatus : Disabled

.LINK
https://blogs.technet.microsoft.com/filecab/2016/09/16/stop-using-smb1/
.LINK
https://gallery.technet.microsoft.com/scriptcenter/Get-SMB1Status-8ecede0e
.LINK
https://support.microsoft.com/en-us/help/2696547/how-to-enable-and-disable-smbv1,-smbv2,-and-smbv3-in-windows-vista,-windows-server-2008,-windows-7,-windows-server-2008-r2,-windows-8,-and-windows-server-2012
#>
function Get-SMBStatus {
    [CmdletBinding()]
    param (
    [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   ValueFromPipeline=$true,
                   Position=0)]
    [string[]]$ComputerName = $env:COMPUTERNAME,
    [System.Management.Automation.PSCredential]$Credential = [System.Management.Automation.PSCredential]::Empty
    )


    begin {
        
        #region Get-SMBServerStatus
        # Helper function to get the SMB Server status for each applicable version
        function Get-SMBServerStatus {
            
            $VerbosePreference = 'Continue'
            
            #region Get-SMBServerRegistry
            # Helper function to get the SMB Server status from the registry for each version.
            function Get-SMBServerRegistry {
            param (
                [ValidateSet('SMB1','SMB2','SMB3')]
                [string]$SMBVersion
                )
                try {
                    $ErrorActionPreference = 'Stop'
                    $SMBServerRegistry = Get-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters -Name $SMBVersion
                                    
                    # Evaluating SMB version Server status
                    if ($SMBServerRegistry.$SMBVersion -eq 0) {
                        Write-Verbose "$SMBVersion registry key exists and is set to 0."
                        $SMBServerRegistryStatus = 'Disabled'
                        }
                    elseif ($SMBServerRegistry.$SMBVersion -eq 1) {
                        Write-Verbose "$SMBVersion registry key exists and is set to 0."
                        $SMBServerRegistryStatus = 'Enabled'
                        }
                    else {
                        Write-Verbose "$SMBVersion registry key is null."
                        $SMBServerRegistryStatus = $null
                    }
                    
                    $SMBServerRegistryStatus
                }
        
                catch {
                    Write-Verbose -Message "$SMBVersion key value not found on $env:COMPUTERNAME."
                    $SMBServerRegistryStatus = 'Enabled'
                    $SMBServerRegistryStatus
                    }
                }
            #endregion
            
            # Get operating system version to check for supported SMB server versions
            $OS = Get-WmiObject -Class win32_operatingsystem
            Write-Verbose "$($env:COMPUTERNAME) is running $($OS.Caption) version $($OS.Version)."
            if ([version]$OS.version -ge [version]'6.0' -and [version]$OS.version -lt [version]'6.2') {
                # SMB1 supported
                $SMB1ServerStatus = Get-SMBServerRegistry -SMBVersion SMB1
                # SMB2 supported
                $SMB2ServerStatus = Get-SMBServerRegistry -SMBVersion SMB2
                # SMB3 unsupported
                $SMB3ServerStatus = 'Unsupported'
                }
            elseif ([version]$OS.version -ge [version]'6.2') {
                # SMB1 supported
                $SMB1ServerStatus = Get-SMBServerRegistry -SMBVersion SMB1
                # SMB2 supported
                $SMB2ServerStatus = Get-SMBServerRegistry -SMBVersion SMB2
                # SMB3 supported
                $SMB3ServerStatus = Get-SMBServerRegistry -SMBVersion SMB3
                }
            else {
                # SMB1 supported
                $SMB1ServerStatus = Get-SMBServerRegistry -SMBVersion SMB1
                # SMB2 unsupported
                $SMB2ServerStatus = 'Unsupported'
                # SMB3 unsupported
                $SMB3ServerStatus = 'Unsupported'
                }
            
            $SMBServerStatusProperties = @{
                    SMB1ServerStatus = $SMB1ServerStatus
                    SMB2ServerStatus = $SMB2ServerStatus
                    SMB3ServerStatus = $SMB3ServerStatus
                }
            $SMBServerStatus = New-Object -TypeName PSCustomObject -Property $SMBServerStatusProperties
            $SMBServerStatus
            }
        #end region

        #region Get-SMB1ClientStatus
        function Get-SMB1ClientStatus {
            try {
                $SMB1ClientServiceDependency = Get-Service -name LanManWorkstation -RequiredServices -ErrorAction Stop | Where-Object -FilterScript {$_.Name -eq 'MrxSmb10'}
                if ($SMB1ClientServiceDependency) {
                    $SMB1ClientStatus = 'Enabled'
                    }
                else {
                    $SMB1ClientStatus = 'Disabled'
                    }
                $SMB1ClientStatus
                }
            catch {
                $SMB1ClientStatus = $null
                $SMB1ClientStatus
                }
            }
        #endregion

    }

    process {
        foreach ($Computer in $ComputerName) {
            try {
                Write-Verbose -Message "Checking SMB status for $Computer"
                $Session = New-PSSession -ComputerName $Computer -ErrorAction Stop -Credential $Credential
                $SMBServerStatus = Invoke-Command -ScriptBlock ${function:Get-SMBServerStatus} -Session $Session
                $SMB1ClientStatus = Invoke-Command -ScriptBlock ${function:Get-SMB1ClientStatus} -Session $Session
                Remove-PSSession -Session $Session

                $SMBStatusProperties = [ordered]@{
                    ComputerName = $Computer
                    SMB1ServerStatus = $SMBServerStatus.SMB1ServerStatus
                    SMB2ServerStatus = $SMBServerStatus.SMB2ServerStatus
                    SMB3ServerStatus = $SMBServerStatus.SMB3ServerStatus
                    SMB1ClientStatus = $SMB1ClientStatus
                    }
                $SMBStatus = New-Object -TypeName pscustomobject -Property $SMBStatusProperties
                $SMBStatus

                }
            catch {
                Write-Error $Error[0].ErrorDetails
                return
                }
            }
        }
    end {}
    }
