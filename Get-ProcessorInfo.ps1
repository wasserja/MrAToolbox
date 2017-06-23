<#
.Synopsis
   Get the processor information of a local or remote computer
   including number of cores and processor speed.
.DESCRIPTION
   Get the processor information of a local or remote computer
   including number of cores and processor speed.

   Created by: Jason Wasser
   Modified: 1/13/2015

   from: http://blogs.technet.com/b/heyscriptingguy/archive/2011/09/26/use-powershell-and-wmi-to-get-processor-information.aspx 
.EXAMPLE
   Get-ProcessorInfo
   Gets the processor information of the local computer.
.EXAMPLE
   Get-ProcessorInfo -ComputerName SERVER01
   Gets the processor information of SERVER01.
.EXAMPLE
   Get-ProcessorInfo -ComputerName (Get-Content c:\temp\computerlist.txt)
   Gets the processor information of a list of computers.
#>
Function Get-ProcessorInfo
{
    [CmdletBinding()]
    [Alias("gpi")]
    [OutputType([int])]
    Param
    (
        # Computer Name
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [string[]]$ComputerName=$env:COMPUTERNAME
    )

    Begin {}
    Process
    {
        foreach ($Computer in $ComputerName) {
            $Property = "systemname","Name","maxclockspeed","addressWidth","numberOfCores","NumberOfLogicalProcessors"
            Get-WmiObject -class win32_processor -ComputerName $Computer -Property $property | Select-Object -Property $Property
            }
    }
    End {}
}