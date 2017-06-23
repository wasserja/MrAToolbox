<#
.SYNOPSIS
   Set-IPAddress allows you to set an IP address, subnet mask, gateway,
   and DNS servers for a network adapter. 
   
.DESCRIPTION
   Set-IPAddress allows you to set an IP address, subnet mask, gateway,
   and DNS servers for a network adapter. 

   Windows 8/2012 and above have built-in cmdlets for Set-NetIPAddress, but any downlevel 
   clients and servers are stuck with netsh. This script can still be used for Windows 8/2012
   and above since the WMI methods are still available. 

   Requires:
    * Write-Log - https://gallery.technet.microsoft.com/scriptcenter/Write-Log-PowerShell-999c32d0
    * Send-Log - https://gallery.technet.microsoft.com/scriptcenter/Send-Log-PowerShell-f4de1581

.NOTES
 
 Created by: Jason Wasser
 Modified: 11/23/2015 01:47:23 PM
 
 Changelog:
  * Set $PSDefaultParameterValues for Write-Log
  * Moved sleep to the End section to save time.   

 TODO:
  * Do we even want to attempt to feed computer names or just assume locally? 
    This would require more testing and working with remote wmi. Plus changing
    an IP address of a remote computer during the script would not work well.
  * Re-enable DHCP

.EXAMPLE
   Set-IPAddress -NetworkAdapterName "Local Area Connection" -IPAddress 192.168.1.50 -SubnetMask 255.255.255.0 -Gateway 192.168.1.1 -DNSServers 192.168.1.1,8.8.8.8
   Sets the IP address, subnet mask, gateway, and DNS servers for Local Area Connection.
.EXAMPLE
   Set-IPAddress -NetworkAdapterName "Local Area Connection" -IPAddress 192.168.1.50 -SubnetMask 255.255.255.0
   Sets the IP address and subnet mask for Local Area Connection.
.EXAMPLE
   Set-IPAddress -NetworkAdapterName "Local Area Connection" -IPAddress 192.168.1.50 -SubnetMask 255.255.255.0 -ReplaceExisting $false
   Adds the IP address and subnet mask to Local Area Connection keeping the existing IP configuration.
#>
function Set-IPAddress {
    [CmdletBinding()]
    #[OutputType([int])]
    Param
    (
        # Network Interface Name
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [Alias("NIC")]
        [string]$NetworkAdapterName,

        # IP address
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=1)]
        [ipaddress[]]$IPAddress,

        # Subnet Mask
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=2)]
        [Alias('Netmask')]
        [ipaddress[]]$SubnetMask,

        # Gateway
        [Parameter(Mandatory=$false,Position=3)]
        [ipaddress]$Gateway,

        # DNS Server(s)
        [Parameter(Mandatory=$false,Position=4)]
        [ipaddress[]]$DNSServers,

        # Default to replace existing IP configuration.
        [Parameter(Mandatory=$false)]
        [bool]$ReplaceExisting=$true,

        # Path to log file
        [Parameter(Mandatory=$false)]
        [String]$LogFileName="C:\Logs\SetIPAddress.log",
        
        # Include to send copy of log via email
        [Parameter(Mandatory=$false)]
        [switch]$SendLog,

        # Email Parameters
        [string]$SmtpServer = "smtp.domain.com",
        [string]$ToAddress = "it.distro@domain.com",
        [string]$FromAddress = "automaton@domain.com",
        [string]$Subject = "Automaton Alert $(get-date -Format "MM/dd/yyyy HH:mm") - Set-StaticIPAddress for $($env:COMPUTERNAME)",
        [string]$MessageBody = "Please see attached.`n`nSincerely,`nYour friendly AutoMaton.",
        [int]$Port = 25,
        [System.Management.Automation.PSCredential]$Credential = [System.Management.Automation.PSCredential]::Empty
        
    )
Begin 
{
    # Set Default Log Path for Write-Log
    $PSDefaultParameterValues = @{"Write-Log:Path"="C:\Logs\SetIPAddress.log"}

    
    # Worker Function that actually changes the IP configuration.
    function Set-IP {
        # IP Address and Subnet Mask
        if ($IPAddress) {
            if (!$SubnetMask) {
                Write-Log "Subnet Mask was not provided." -LogPath $LogFileName -Level Error
                return
                }
            else {
                Write-Log "Setting IP Address(es) for $($NetworkAdapter.NetConnectionID)`: $IPAddress" -LogPath $LogFileName
                Write-Log "Subnet Mask(s): $SubnetMask" -LogPath $LogFileName
                
                $StaticIPResult = $NetworkConfig.EnableStatic($IPAddress, $SubnetMask)
                if ($StaticIPResult.ReturnValue -ne 0) {
                    Write-Log "Error setting IP: $($StaticIPResult.ReturnValue)" -Level Error
                    }    
                }
            }
        else {
            # No IP address specified.
            Write-Log "No IP address specified." 
            }
            
        # Gateway
        if ($Gateway) {
            Write-Log "Setting Gateway: $Gateway" 
            $GatewayResult = $NetworkConfig.SetGateways($Gateway, 1)
            if ($GatewayResult.ReturnValue -ne 0) {
                Write-Log  "Error setting gateway: $($GatewayResult.ReturnValue)"  -Level Error
                }
            }
        else {
            # No gateway specified
            Write-Log "No gateway specified." 
            }

        # DNS
        if ($DNSServers) {
            Write-Log "Setting DNS: $DNSServers" 
            $DNSResult = $NetworkConfig.SetDNSServerSearchOrder(@($DNSServers))
            if ($DNSResult.ReturnValue -ne 0) {
                Write-Log "Error setting DNS: $($DNSResult.ReturnValue)"  -Level Error
                }
            }
        else {
            # No DNS Specified
            Write-Log "No DNS specified." 
            }

        # After making the change we should log the new configuration.
        $NetworkConfig = Get-WmiObject -Class Win32_NetworkAdapterConfiguration -Filter "Index = $($NetworkAdapter.Index)"

        Write-Log "New IP Configuration: $($NetworkConfig.IPAddress)" 
        Write-Log "New Subnet Configuration: $($NetworkConfig.IPSubnet)" 
        Write-Log "New Gateway Configuration: $($NetworkConfig.DefaultIPGateway)" 
        Write-Log "New DNS Configuration: $($NetworkConfig.DNSServerSearchOrder)" 
        }

    # Begin Logging
    Write-Log "--------------------------------------------" 
    Write-Log "Beginning $($MyInvocation.InvocationName) on $($env:COMPUTERNAME) by $env:USERDOMAIN\$env:USERNAME"
    }
Process 
    {
    
    # Get the network adapter that matches the provided name. Wildcards are supported, but for safety we can only match one adapter.
    # Although it is better to filter left, I chose to use Where to filter the network adapter name
    # to be able to use standard wildcards for quicker shorthand (i.e. -NIC *local*).
    #$NetworkAdapter = Get-WmiObject -Class win32_NetworkAdapter -Filter "NetConnectionID like '$NetworkAdapterName'" -ErrorAction Stop
    $NetworkAdapter = Get-WmiObject -Class win32_NetworkAdapter -ErrorAction Stop | Where-Object -FilterScript {$_.NetConnectionID -like "$NetworkAdapterName"}
    if ($NetworkAdapter) {
        if ($NetworkAdapter.Count -gt 1) {
            Write-Log "More than one network adapter matches $NetworkAdapterName"  -Level Error
            }
        else {
            #$NetworkConfig = Get-WmiObject -class Win32_NetworkAdapterConfiguration -Filter "IpEnabled = 'True' and Index = $($NetworkAdapter.Index)"
            $NetworkConfig = Get-WmiObject -Class Win32_NetworkAdapterConfiguration -Filter "Index = $($NetworkAdapter.Index)"
                
            # By default we will replace the existing IP configuration with what was supplied.                
            if ($ReplaceExisting) {
                Set-IP
                }
            else {
                # If we want to keep the existing IP address configuration, the $ReplaceExisting must be false.
                # This would be used if the user wished to add an additional IP address to an adapter.
                # We have to read the current IP address and subnet mask and then add it.
                # Reading the current IP address(es) may return a IPv6 which cannot be assigned through
                # the current WMI method. We need to strip out any IPv6 addresses and their corresponding 
                # subnet masks.
                $CurrentIPAddress = @()
                $CurrentSubnet = @()
                $CurrentIPAddress += $NetworkConfig.IPAddress | Where-Object {($_ -as [ipaddress]).AddressFamily -eq "InterNetwork"}
                Write-Log "Current IP Address(es): $CurrentIPAddress" 
                foreach ($Address in $CurrentIPAddress) {
                    $CurrentSubnet += $NetworkConfig.IPSubnet[[array]::IndexOf($NetworkConfig.IPAddress, $Address)]
                    }
                Write-Log "Current Subnet(s): $CurrentSubnet" 
                    
                # Composite arrays of existing IP address(es) and additional IP address(es).
                $IPAddress = $CurrentIPAddress + $IPAddress
                $SubnetMask = $CurrentSubnet + $SubnetMask
                Set-IP
                }
            }
        }
    # No matching network adapter found.
    else {
        Write-Log "Unable to find a network adapter named $NetworkAdapterName"  -Level Error
        }   
    }
End 
    {
    # Adding a pause to allow the network card to apply the new settings.
    Write-Log "Pausing to allow the network card to apply the new settings." 
    Start-Sleep -Seconds 5

    # Clean up
    Write-Log "$($MyInvocation.InvocationName) complete." 
    Write-Log "--------------------------------------------" 
    # Send the user a copy of the log if requested.
    if ($SendLog) {
        # Creating anonymous credential
            if ($Credential.Username -eq $null) {
                $SecurePassword = ConvertTo-SecureString -String 'anonymous' -AsPlainText -Force
                $Credential = New-Object System.Management.Automation.PSCredential('anonymous',$SecurePassword)
            }
        Send-Log -Path $LogFileName -SmtpServer $SmtpServer -ToAddress $ToAddress -FromAddress $FromAddress -Subject $Subject -Username $Username -Password $Password -Port $Port
        }
    # Rotate Log file
    if (Test-Path $LogFileName) {
        $TimeStamp = Get-Date -Format "yyyyMMddhhmmss"
        $LogFilePath = Get-ChildItem -Path $LogFileName
        Rename-Item $LogFileName -NewName "$($LogFilePath.BaseName)-$TimeStamp.log"
        }

    }
}