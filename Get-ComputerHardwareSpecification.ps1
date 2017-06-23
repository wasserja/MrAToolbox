<#
.SYNOPSIS
Get the hardware specifications of a Windows computer.

.DESCRIPTION
Get the hardware specifications of a Windows computer including CPU, memory, and storage.
The Get-ComputerHardwareSpecification function uses CIM to retrieve the following specific
information from a local or remote Windows computer.
CPU Model
Current CPU clock speed
Max CPU clock speed
Number of CPU sockets
Number of CPU cores
Number of logical processors
CPU hyperthreading
Total amount of physical RAM
Total amount of storage

.PARAMETER ComputerName
Enter a computer name

.PARAMETER Credential
Enter a credential to be used when connecting to the computer.

.EXAMPLE
Get-ComputerHardwareSpecification

ComputerName      : workstation01
CpuName           : Intel(R) Core(TM) i7-2600 CPU @ 3.40GHz
CurrentClockSpeed : 3401
MaxClockSpeed     : 3401
NumberofSockets   : 1
NumberofCores     : 4
LogicalProcessors : 8
HyperThreading    : True
Memory(GB)        : 16
Storage(GB)       : 697.96

.EXAMPLE
Get-ComputerHardwareSpecification -ComputerName server02

ComputerName      : server02
CpuName           : Intel(R) Core(TM) i7-2600 CPU @ 3.40GHz
CurrentClockSpeed : 3401
MaxClockSpeed     : 3401
NumberofSockets   : 1
NumberofCores     : 4
LogicalProcessors : 8
HyperThreading    : True
Memory(GB)        : 16
Storage(GB)       : 697.96

.NOTES
Created by: Jason Wasser @wasserja
Modified: 6/14/2017 02:18:45 PM 
Requires the New-ResilientCimSession function
.LINK
New-ResilientCimSession 
https://gallery.technet.microsoft.com/scriptcenter/Establish-CimSession-in-b2166b02
.LINK
https://gallery.technet.microsoft.com/scriptcenter/Get-ComputerHardwareSpecifi-cf7df13d
#>
function Get-ComputerHardwareSpecification {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0)]
        [string[]]$ComputerName = $env:COMPUTERNAME,
        [System.Management.Automation.PSCredential]$Credential = [System.Management.Automation.PSCredential]::Empty
    )
    begin {}

    process {
        foreach ($Computer in $ComputerName) {
            $ErrorActionPreference = 'Stop'
            # Establishing CIM Session
            try {
                Write-Verbose -Message "Attempting to get the hardware specifications of $Computer"
                $CimSession = New-ResilientCimSession -ComputerName $Computer -Credential $Credential
                
                Write-Verbose -Message "Gathering CPU information of $Computer"
                $CPU = Get-CimInstance -ClassName win32_processor -CimSession $CimSession

                Write-Verbose -Message "Gathering memory information of $Computer"
                $Memory = Get-CimInstance -ClassName win32_operatingsystem -CimSession $CimSession
            
                Write-Verbose -Message "Gathering storage information of $Computer"
                $Disks = Get-CimInstance -ClassName win32_logicaldisk -Filter "DriveType = 3" -CimSession $CimSession
                $Storage = "{0:N2}" -f (($Disks | Measure-Object -Property Size -Sum).Sum / 1Gb) -as [decimal]
            
                # Building object properties
                $SystemProperties = [ordered]@{
                    ComputerName      = $Memory.PSComputerName
                    CpuName           = ($CPU | Select-Object -Property Name -First 1).Name
                    CurrentClockSpeed = ($CPU | Select-Object -Property CurrentClockSpeed -First 1).CurrentClockSpeed
                    MaxClockSpeed     = ($CPU | Select-Object -Property MaxClockSpeed -First 1).MaxClockSpeed
                    NumberofSockets   = $CPU.SocketDesignation.Count
                    NumberofCores     = ($CPU | Measure-Object -Property NumberofCores -Sum).Sum 
                    LogicalProcessors = ($CPU | Measure-Object -Property NumberOfLogicalProcessors -Sum).Sum
                    HyperThreading    = ($CPU | Measure-Object -Property NumberOfLogicalProcessors -Sum).Sum -gt ($CPU | Measure-Object -Property NumberofCores -Sum).Sum 
                    'Memory(GB)'      = [int]($Memory.TotalVisibleMemorySize / 1Mb)
                    'Storage(GB)'     = $Storage
                }
                    
                $ComputerSpecs = New-Object -TypeName psobject -Property $SystemProperties
                $ComputerSpecs
                Remove-CimSession -CimSession $CimSession
            }
            catch {
                $ErrorActionPreference = 'Continue'
                Write-Error -Message "Unable to connect to $Computer"
            }
        }
    }
    end {}
}