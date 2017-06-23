<#
.Synopsis
   Get-OS does a WMI call to get basic operating system information.
.DESCRIPTION
   Get-OS does a WMI call to get basic operating system information.
.NOTES
   Created by: Jason Wasser @wasserja
   Modified: 5/15/2017 04:48:10 PM 
.EXAMPLE
Get-OS

ComputerName       : COMPUTER01
OS Name            : Microsoft Windows 10 Enterprise
ServicePack        : 0
Architecture       : 64-bit
Version            : 10.0.14393
OperatingSystemSKU : 4
InstallDate        : 8/3/2016 2:10:49 PM

Gets the operating system information for the local system.

.EXAMPLE
Get-OS -ComputerName SERVER1

ComputerName       : SERVER1
OS Name            : Microsoft Windows Web Server 2008 R2
ServicePack        : 1
Architecture       : 64-bit
Version            : 6.1.7601
OperatingSystemSKU : 17
InstallDate        : 3/11/2011 2:24:33 AM

Get the operating system from SERVER1
.LINK
https://gallery.technet.microsoft.com/Get-OS-Get-Windows-7a140942
#>
function Get-OS {
    [CmdletBinding()]
    [Alias()]
    Param
    (
        [Parameter(Mandatory=$false,
                    ValueFromPipelineByPropertyName=$true,
                    ValuefromPipeline=$true,
                    Position=0)]
        [string[]]$ComputerName=$env:COMPUTERNAME
    )

    Begin
    {
    }
    Process
    {
        
        foreach ($Computer in $ComputerName) {
            $OSInfo = Get-WmiObject win32_OperatingSystem -ComputerName $Computer
            $OSInfo | Select-Object -Property @{Name="ComputerName";expression={$_.__SERVER}},@{Name="OS Name";expression={$_.Caption}},@{Name="ServicePack";expression={$_.ServicePackMajorVersion}},@{Name="Architecture";expression={$_.OSArchitecture}},Version,OperatingSystemSKU,@{Name='InstallDate';expression={$_.ConvertToDateTime($_.InstallDate)}}
            }
    }
    End
    {
    }
    }