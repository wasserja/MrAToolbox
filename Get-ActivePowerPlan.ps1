<#
.SYNOPSIS
Get the active power plan of a computer.

.DESCRIPTION
Get the active power plan of a computer.

.PARAMETER ComputerName
Enter a computer name.

.PARAMETER Credential
Enter a credential for accessing a remote computer.

.EXAMPLE
Get-ActivePowerPlan

ComputerName  ActivePowerPlan
------------  ---------------
DEATHSTAR01   High performance

.EXAMPLE
Get-ActivePowerPlan -Computer COMPUTER33 -Credential (Get-Credential)

ComputerName  ActivePowerPlan
------------  ---------------
COMPUTER33    High performance

.NOTES
Created by: Jason Wasser @wasserja
Modified: 7/11/2017 01:38:06 PM 
#>
function Get-ActivePowerPlan {
    [CmdletBinding()]
    param (
        [string[]]$ComputerName = $env:COMPUTERNAME,
        [System.Management.Automation.PSCredential]$Credential = [System.Management.Automation.PSCredential]::Empty

    )
    
    begin {
    }
    
    process {
        foreach ($Computer in $ComputerName) {
            
            # Establish CIM Session
            $CimSessionParams = @{
                ComputerName = $Computer
                Protocol = 'Wsman'
                Credential = $Credential
                ErrorAction = 'Stop'
            }
            
            Write-Verbose -Message "Attempting to establish CIM session to $Computer"
            try {
                $CimSession = New-ResilientCimSession @CimSessionParams
            }
            catch {
                Write-Error "Unable to establish CIM session to $Computer"
                continue
            }
            
            Write-Verbose -Message "Successfully established CIM session to $Computer"

            # Gathering CIM data
            $CimInstanceParams = @{
                    Namespace = 'root\cimv2\power'
                    Class = 'win32_powerplan'
                    Filter = "isActive='true'"
                    CimSession = $CimSession
            }
            
            Write-Verbose -Message "Gathering active power plan for $Computer"
            $PowerPlan = Get-CimInstance @CimInstanceParams
            $ActivePowerPlanProperties = [ordered]@{
                ComputerName    = $PowerPlan.PSComputerName
                ActivePowerPlan = $PowerPlan.ElementName
            }
            $ActivePowerPlan = New-Object -TypeName PSCustomObject -Property $ActivePowerPlanProperties
            $ActivePowerPlan

            # Tear down session
            Write-Verbose -Message "Removing CIM session to $Computer"
            Remove-CimSession -CimSession $CimSession
        }
    }
    end {
    }
}
