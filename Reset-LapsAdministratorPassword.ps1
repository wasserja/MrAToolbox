<#
.SYNOPSIS
Reset the local administrator password using LAPS.

.DESCRIPTION
This function sets the LAPS password expiration for a target computer to a date and time in the past (now minus one day).
After which a group policy refresh is called to allow the LAPS group policy client-side extension to change
the password.

The LAPS password expiration attribute, ms-Mcs-AdmPwdExpirationTime, is based on local time zone. Due to the 
possible difference between the timezone of the target computer and the executing computer, the function
sets the password expiration to one day before right now.

The function must be called from an account that has the privilige to change the ms-Mcs-AdmPwdExpirationTime
attribute in Active Directory.

The function attempts to make the change on a domain controller in the site where the computer resides.

.PARAMETER ComputerName
Enter a computer name.

.EXAMPLE
Reset-LapsAdministratorPassword -ComputerName DRONEPC01

.NOTES
Created by: Jason Wasser @wasserja
Modified: 7/13/2017 10:08:11 AM 

#>
#requires -modules ActiveDirectory
function Reset-LapsAdministratorPassword {
    [CmdletBinding()]
    param (
        [parameter(
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true)]
        [string[]]$ComputerName = $env:COMPUTERNAME,
        [System.Management.Automation.PSCredential]$Credential = [System.Management.Automation.PSCredential]::Empty
    )
    
    begin {

        function Get-ADSitebyComputerName {
            param (
                $SiteNameRegistryKey = 'HKLM:\SYSTEM\CurrentControlSet\Services\Netlogon\Parameters\',
                $SiteNameRegistryValue = 'DynamicSiteName'
            )
            $ADSiteName = (Get-Item -Path $SiteNameRegistryKey).GetValue($SiteNameRegistryValue)
            $ADSiteName
        }
    }
    
    process {
        $ErrorActionPreference = 'Stop'
        $LapsPasswordExpirationAttribute = 'ms-Mcs-AdmPwdExpirationTime'
        foreach ($Computer in $ComputerName) {
            try {
                
                Write-Verbose -Message "Establishing remote session on $Computer"
                $Session = New-PSSession -ComputerName $Computer -Credential $Credential
                Write-Verbose "Successfully established session with $($Session.ComputerName)"

                Write-Verbose -Message "Getting Active Directory site of $Computer"
                $ADSiteName = Invoke-Command -Session $Session -ScriptBlock ${function:Get-ADSitebyComputerName}
                Write-Verbose -Message "$Computer is in Active Directory Site $ADSiteName"

                Write-Verbose -Message "Locating domain controller in AD site $ADSiteName"
                $ADDomainController = Get-ADDomainController -Discover -SiteName $ADSiteName
                Write-Verbose -Message "Located domain controller $($ADDomainController.Name)"

                Write-Verbose -Message "Setting LAPS password expiration attribute $LapsPasswordExpirationAttribute on AD Server $($ADDomainController.Name) for $Computer."
                if ($Credential.UserName -ne $null) {
                    Set-ADComputer -Identity $Computer -Replace @{"$LapsPasswordExpirationAttribute" = $(Get-Date).AddDays(-1).Ticks} -Credential $Credential
                }
                else {
                    Set-ADComputer -Identity $Computer -Replace @{"$LapsPasswordExpirationAttribute" = $(Get-Date).AddDays(-1).Ticks}
                }
                Write-Verbose -Message "The LAPS password expiration attribute for $Comptuer has been set to $((Get-ADcomputer -Identity $Computer -Properties $LapsPasswordExpirationAttribute).$LapsPasswordExpirationAttribute)"

                Write-Verbose -Message "Invoking group policy update on $Computer to force LAPS to change the password."
                Invoke-Command -Session $Session -ScriptBlock {gpupdate.exe /target:computer}
                Write-Verbose -Message "Group policy refresh has been initiated on $Computer"

                Write-Verbose -Message "Removing remote session on $Computer"
                Remove-PSSession -Session $Session

            }
        
            catch {
                Write-Error -Message $_.Exception
                if ($Session.Name) {
                    Remove-PSSession -Session $Session
                }
            }
        }
    }
    
    end {
    }
}