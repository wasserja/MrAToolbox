<#
.SYNOPSIS
Test a computer for LAPS compliance.

.DESCRIPTION
The Local Administrator Password Solution is a tool you can install on
your computers to periodically change the local administrator password.
This function will validate if the LAPS client-side extension is installed,
if the registry has policy keys configured, and if the local administrator
password has been reset within the configured range.

.PARAMETER ComputerName
Enter a computer name

.PARAMETER Credential
Enter a valid credential for accessing the remote computer.

.EXAMPLE
Get-LapsCompliance -ComputerName WORKSHOP01 -Credential (Get-Credential)

.NOTES
Created by: Jason Wasser @wasserja
Modified: 7/12/2017 04:11:42 PM 
#>
function Test-LapsCompliance {
    [CmdletBinding()]
    param (
        [parameter(
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true)]    
        [string[]]$ComputerName = $env:COMPUTERNAME,
        [System.Management.Automation.PSCredential]$Credential = [System.Management.Automation.PSCredential]::Empty
    )
    
    begin {
        function Test-LapsInstallation {
            param (
                $LapsInstallationPath = 'C:\Program Files\LAPS\CSE\AdmPwd.dll'
            )
            Test-Path ($LapsInstallationPath)
        }

        function Test-LapsPolicyConfiguration {
            param (
                $RegistryPolicyPath = 'HKLM:\SOFTWARE\Policies\Microsoft Services\AdmPwd\'
            )
            if (Test-Path -Path $RegistryPolicyPath) {
                $LapsRegistryPolicyConfiguration = Get-Item -Path $RegistryPolicyPath
                
                $LapsPolicyConfigurationProperties = @{}
                foreach ($Property in $LapsRegistryPolicyConfiguration.Property) {
                    $LapsPolicyConfigurationProperties.Add($Property, $LapsRegistryPolicyConfiguration.GetValue($Property))
                }
                $LapsPolicyConfigurationProperties.Add('IsLapsConfigured', $true)
                $LapsPolicyConfiguration = New-Object -TypeName PSCustomObject -Property $LapsPolicyConfigurationProperties
                $LapsPolicyConfiguration
            }
            else {
                $LapsPolicyConfiguration = $false
                $LapsPolicyConfiguration
            }
    
        }

        function Test-LapsAdministratorPassword {
            param (    
                [int]$PasswordAgeDays,
                [datetime]$PasswordLastSet
            )

            $LocalAdministratorPasswordAgeinDays = (New-TimeSpan -Start $PasswordLastSet -End (Get-Date)).Days
            if ($LocalAdministratorPasswordAgeinDays -le $PasswordAgeDays) {
                $LapsAdministratorPasswordValidity = $true
            }
            else {
                $LapsAdministratorPasswordValidity = $false
            }
            $LapsAdministratorPasswordValidity

        }

    }
    
    process {
        $ErrorActionPreference = 'Stop'
        foreach ($Computer in $ComputerName) {

            try {

            
                # Setup session
                $Session = New-PSSession -ComputerName $Computer -Credential $Credential

                # Is LAPS installed
                Write-Verbose -Message "Checking to see if LAPS is installed on $Computer"
                $IsLapsInstalled = Invoke-Command -Session $Session -ScriptBlock ${function:Test-LapsInstallation}
            
                if ($IsLapsInstalled) {
                    Write-Verbose -Message "LAPS is installed on $Computer"
                
                    # Are LAPS-related registry-related policy items configured - Test-LapsPolicyConf
                    Write-Verbose -Message "Checking to see if LAPS is configured on $Computer"
                    $IsLapsConfigured = Invoke-Command -Session $Session -ScriptBlock ${function:Test-LapsPolicyConfiguration}

                    if ($IsLapsConfigured) {
                        Write-Verbose -Message "LAPS registry policy keys were found on $Computer"

                        # Has the local administrator password been reset within the configured time
                        $LocalAdministratorPasswordLastSet = Get-LocalAdministratorPasswordLastSet -ComputerName $Computer -Credential $Credential
                        $IsLapsLocalAdministratorPasswordValid = Invoke-Command -Session $Session -ScriptBlock ${function:Test-LapsAdministratorPassword} -ArgumentList $IsLapsConfigured.PasswordAgeDays, $LocalAdministratorPasswordLastSet.PasswordLastSet

                        if ($IsLapsLocalAdministratorPasswordValid) {
                            Write-Verbose -Message "The local administrator password on $Computer was last set on $($LocalAdministratorPasswordLastSet.PasswordLastSet) which is within $($IsLapsConfigured.PasswordAgeDays) days."
                            $IsLapsCompliant = $true
                        
                        }
                        else {
                            Write-Warning -Message "The local administrator password on $Computer was last set on $($LocalAdministratorPasswordLastSet.PasswordLastSet) which is NOT within $($IsLapsConfigured.PasswordAgeDays) days."
                            $IsLapsCompliant = $false
                        }
                    }
                    else {
                        Write-Warning -Message "LAPS registry policy keys were NOT found on $Computer"
                        $IsLapsCompliant = $false
                    }
                }
                else {
                    Write-Warning -Message "LAPS is not installed on $Computer."
                    $IsLapsCompliant = $false
                }

                $LapsComplianceProperties = [ordered]@{
                    ComputerName                          = $Session.ComputerName
                    IsLapsInstalled                       = $IsLapsInstalled
                    IsLapsConfigured                      = $IsLapsConfigured.IsLapsConfigured
                    IsLapsLocalAdministratorPasswordValid = $IsLapsLocalAdministratorPasswordValid
                    IsLapsCompliant                       = $IsLapsCompliant
                }

                $LapsCompliance = New-Object -TypeName PSCustomObject -Property $LapsComplianceProperties
                $LapsCompliance

                # Tear down session
                Remove-PSSession $Session
            }
            catch [System.Management.Automation.Remoting.PSRemotingTransportException] {
                Write-Error -Message $Error[0].Exception
            }
            catch {
                Write-Error -Message $Error[0].Exception
                if ($Session.Name) {
                    Remove-PSSession -Session $Session
                }
            }
        }
    }

    end {
    }
}