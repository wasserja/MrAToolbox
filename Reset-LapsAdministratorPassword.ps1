<#
.SYNOPSIS
Short description

.DESCRIPTION
Long description

.PARAMETER ComputerName
Parameter description

.EXAMPLE
An example

.NOTES
General notes

I need to verify the invoke-gpupdate is actually working. it doesn't appear to be.


#>
#requires -modules AdmPwd.PS
function Reset-LapsAdministratorPassword {
    [CmdletBinding()]
    param (
        [string[]]$ComputerName = $env:COMPUTERNAME
    )
    
    begin {
    }
    
    process {
        foreach ($Computer in $ComputerName) {
            try {
                Write-Verbose -Message "Attempting to reset local administrator password on $Computer"
                Reset-AdmPwdPassword -ComputerName $Computer -WhenEffective (Get-Date) -ErrorAction Stop
                Write-Verbose -Message "Attempting to invoke a group policy update to force LAPS to change the password."
                Invoke-GPUpdate -Computer $Computer -Target Computer
            }
            catch [System.DirectoryServices.Protocols.DirectoryOperationException] {
                Write-Error -Message $Error[0].Exception
            }
            catch {
                Write-Error -Message $Error[0].Exception
            }
        }
    }
    
    end {
    }
}