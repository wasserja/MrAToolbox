<#
.Synopsis
Update-DnsServerResourceRecordA simplifies the process of updating a DNS
record.
.DESCRIPTION
Update-DnsServerResourceRecordA simplifies the process of updating a DNS
record. 
.PARAMETER ComputerName
Active Directory/DNS Server(s), default localhost
.PARAMETER ZoneName
DNS Zone Name, default current domain name
.PARAMETER RecordType
Record type, Default A, but AAAA is acceptible
.PARAMETER Name
The name of the A record
.PARAMETER IPAddress
The new IP address for the A record
.PARAMETER Force
Force to create a new resource record if it doesn't exist.
.PARAMETER RRIndex
If you have more than one A record for a given name, the script will
default to change the first one. Use the $Index parameter to choose
a different record.
.EXAMPLE
Update-DnsServerResourceRecordA -Name server01 -IPAddress 10.146.2.250 -ZoneName domain.com
Changes the DNS A record for server01 to 10.146.2.250 on the local DNS server for domain.com.
.EXAMPLE
Update-DnsServerResourceRecordA -Name server01 -IPAddress 10.146.2.250 -ComputerName DC01 -ZoneName domain.com
Changes the DNS A record for server01 to 10.146.2.250 on the DNS server DC01 for domain.com.
.EXAMPLE
Update-DnsServerResourceRecordA -Name server01 -IPAddress 10.146.2.250 -ComputerName DC01 -ZoneName domain.com
Changes the DNS A record for server01 to 10.146.2.250 on the DNS server DC01 for domain.com, and if the record
doesn't exist, the record is created. 
.NOTES
Created by: Jason Wasser
Modified: 4/14/2015 02:00:10 PM 
Version: 1.2

Changelog:
 * Added -AllowUpdateAny on creating a new record.
 * Added the RRIndex parameter so we can account for multiple resource records
   with the same name. Defaulting to first record for simplicity.
.LINK
https://gallery.technet.microsoft.com/scriptcenter/Update-DnsServerResourceRec-4503d9f8
#>
#Requires -Modules DnsServer
function Update-DnsServerResourceRecordA
{
    [CmdletBinding()]
    #[OutputType([Microsoft.Management.Infrastructure.CimInstance#root/Microsoft/Windows/DNS/DnsServerResourceRecord])]
    Param
    (
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [string[]]$ComputerName=$env:COMPUTERNAME,

        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=1)]
        [string]$ZoneName=$env:USERDNSDOMAIN,
        
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=2)]
        [string]$RecordType="A",
        
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=3)]
        [string]$Name,
        
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=4)]
        [ipaddress]$IPAddress,

        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=5)]
        [switch]$Force=$false,

        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=6)]
        [int]$RRIndex=0

    )

    Begin
    {
    }
    Process
    {
        foreach ($Computer in $ComputerName) {
            if (Test-Connection -ComputerName $Computer -Count 1 -Quiet) {
                
                # Get the current resource record.
                try {
                    $OldRR = Get-DnsServerResourceRecord -ComputerName $Computer -Name $Name -RRType $RecordType -ZoneName $ZoneName -ErrorAction Stop
                    $NewRR = Get-DnsServerResourceRecord -ComputerName $Computer -Name $Name -RRType $RecordType -ZoneName $ZoneName -ErrorAction Stop
                    
                    # Ensure that the resource record exists before proceeding.
                    if ($NewRR -and $OldRR) {
                        if ($OldRR.Count) {
                            # More than one record found.
                            $NewRR[$RRIndex].RecordData.IPv4Address=[ipaddress]$IPAddress
                            $UpdatedRR = Set-DnsServerResourceRecord -NewInputObject $NewRR[$RRIndex] -OldInputObject $OldRR[$RRIndex] -ZoneName $ZoneName -ComputerName $Computer -PassThru
                            $UpdatedRR
                            }
                        else {
                            $NewRR.RecordData.IPv4Address=[ipaddress]$IPAddress
                            $UpdatedRR = Set-DnsServerResourceRecord -NewInputObject $NewRR -OldInputObject $OldRR -ZoneName $ZoneName -ComputerName $Computer -PassThru
                            $UpdatedRR
                            }
                        }
                    }
                catch {
                    # If it doesn't exist create it if the -Force parameter.
                    if ($Force) {
                        $NewRR = Add-DnsServerResourceRecordA -ComputerName $Computer -Name $Name -ZoneName $ZoneName -IPv4Address $IPAddress -PassThru -AllowUpdateAny
                        $NewRR
                        }
                    else {
                        Write-Error "Existing record $Name.$ZoneName does not exist. Use -Force to create it."
                        }
                    }
                }
            else {
                Write-Error "Unable to connect to $Computer"
                }
            }
    }
    End
    {
    }
}