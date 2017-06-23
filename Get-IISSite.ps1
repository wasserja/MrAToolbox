<#
.Synopsis
   Get IIS Site information from a local or remote computer.
.DESCRIPTION
   Get IIS Site information from a local or remote computer.
.NOTES
   Created by: Jason Wasser @wasserja
   Modified: 5/3/2017 02:13:17 PM 
.EXAMPLE
   Get-IISSite
.EXAMPLE
   Get-IISSite -ComputerName webserver01
#>
function Get-IISSite
{
    [CmdletBinding()]
    Param
    (
        # ComputerName
        [parameter(ValueFromPipeline=$true,
                    ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [string[]]$ComputerName = $env:COMPUTERNAME,

        # Credential
        [System.Management.Automation.PSCredential]$Credential=[System.Management.Automation.PSCredential]::Empty
    )

    Begin
    {
        
        # Helper Function to do the work of gathering site detail information.
        function Get-IISSiteInformation {
            #$VerbosePreference = 'Continue'
            try {
                Import-Module -Name WebAdministration -ErrorAction Stop
                $Websites = Get-ChildItem IIS:\Sites

                foreach ($Site in $Websites) {
                    Write-Verbose "$($Site.Name) is $($Site.State)"
                    Write-Verbose "$($Site.PhysicalPath)"
    
                    Write-Verbose "Gathering site binding information for $($Site.Name)."
                    [string[]]$Bindings = @()
                    foreach ($Binding in $Site.bindings.Collection) {
                        Write-Verbose "$($Binding.BindingInformation)"
                        $Bindings += $Binding.Protocol + ': ' + $Binding.BindingInformation
                        }

                    # Gather Application Pool Information
                    Write-Verbose -Message 'Gather Application Pool Information'
                    $AppPool = Get-Item -Path "IIS:\AppPools\$($Site.ApplicationPool)"
                    
                    # Creating hash table for object properties                    
                    if ($PSVersionTable.PSVersion.Major -lt 3) {
                        $SiteProperties = @{
                            Name = $Site.name
                            ID = $Site.ID
                            State = $Site.state
                            PhysicalPath = $Site.physicalPath
                            Bindings = $Bindings
                            AppPool = $Site.ApplicationPool
                            ManagedRunTimeVersion = $AppPool.managedRuntimeVersion
                            AppPoolState = $AppPool.state
                            AppPoolIdentityType = $AppPool.processmodel.identityType
                            AppPoolUsername = $AppPool.processmodel.userName
                            ComputerName = $env:COMPUTERNAME
                            }
                        }
                    else {
                        $SiteProperties = [ordered]@{
                            Name = $Site.name
                            ID = $Site.ID
                            State = $Site.state
                            PhysicalPath = $Site.physicalPath
                            Bindings = $Bindings
                            AppPool = $Site.ApplicationPool
                            ManagedRunTimeVersion = $AppPool.managedRuntimeVersion
                            AppPoolState = $AppPool.state
                            AppPoolIdentityType = $AppPool.processmodel.identityType
                            AppPoolUsername = $AppPool.processmodel.userName
                            ComputerName = $env:COMPUTERNAME
                            }
                        }
                    
                    $Site = New-Object -TypeName pscustomobject -Property $SiteProperties
                    if ($PSVersionTable.PSVersion.Major -lt 3) {
                        $Site | Select-Object -Property Name,ID,State,PhysicalPath,Bindings,AppPool,ManagedRunTimeVersion,AppPoolState,AppPoolIdentityType,AppPoolUsername,ComputerName
                        }
                    else {
                        $Site
                        }
                    
                    }
                }
            catch {
                Write-Error $Error[0].Exception.Message
                }
            }

    }
    Process
    {
        
        # Loop through each supplied computer name.
        foreach ($Computer in $ComputerName) {
            
            # Run function locally if localhost.
            if ($Computer -eq $env:COMPUTERNAME) {
                Write-Verbose 'Getting IIS website information from localhost'
                Get-IISSiteInformation
                }
            # Run function via Invoke-Command on remote computers.
            else {
                Write-Verbose "Getting IIS website information from remote computer $Computer"
                Invoke-Command -ScriptBlock ${function:Get-IISSiteInformation} -ComputerName $Computer -Credential $Credential
                }
            }
    }
    End
    {
    }
}