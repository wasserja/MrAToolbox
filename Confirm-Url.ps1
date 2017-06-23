<#
.Synopsis
   Confirm the health of a url by looking for a specific pattern.
.DESCRIPTION
   Confirm the health of a url by looking for a specific pattern. 
   The pattern can also be accompanied by a specific class name. 
   If a certain pattern should not be found, use the $InvertMatch 
   switch to invert the output. The script outputs the Url with a 
   boolean of the health status.

   Confirm-Url requires PowerShell 3.0, specifically the Invoke-WebRequest
   cmdlet. 
.NOTES
   Created by: Jason Wasser @wasserja
   Modified: 5/22/2017

   Changelog:
   v1.1
    * Added Web request output to allow further investigation.
   v1.0
    * Initial script
.PARAMETER Uri
    Provide a single or an array url/uri to confirm.
.PARAMETER Pattern
    Provide a regular expression pattern for which to find on the
    uri.
.PARAMETER ClassName
    Optionally provide a class name in which to search for the 
    pattern.
.PARAMETER InvertMatch
    By default if the pattern is found the URL is considered healthy.
    By using the InvertMatch switch, finding the pattern means the
    URL is unhealthy.    
.EXAMPLE
   Confirm-Url -Uri www.google.com -Pattern 'Google Search'
   Grab the google.com home page and verify if the phrase Google Search is present.
.EXAMPLE
   Confirm-Url -Uri www.domain.com/application -ClassName 'Error' -Pattern 'Website Unavailable' -InvertMatch
   Grab the url and look for the pattern website unavailable in the class error. 
   If it is present then the Url is unhealthy.
.LINK
   https://gallery.technet.microsoft.com/scriptcenter/Confirm-Url-PowerShell-d66e021f
#>
#Requires -version 3.0
function Confirm-Url
{
    [CmdletBinding()]
    [Alias()]
    Param
    (

        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   ValueFromPipeline=$true,
                   Position=0)]
        [string[]]$Uri,
        [string]$Pattern='.',#='Enrollment Unavailable',
        [string]$ClassName,#='main-container'
        [switch]$InvertMatch#=$true
    )

    Begin
    {
    }
    Process
    {
        foreach ($UriInstance in $Uri) {
            try {

                # Attempt to grab Uri provided by user
                Write-Verbose -Message "Trying Uri $UriInstance"
                $WebRequest = Invoke-WebRequest -Uri $UriInstance -ErrorAction Stop
                
                # If a class name was provided apply filter script to that section of the page.
                if ($ClassName) {
                    Write-Verbose "ClassName Parameter detected: $ClassName"
                    if ($WebRequest.AllElements | Where-Object -FilterScript {$_.class -eq $ClassName} | Select-Object -First 1 -ExpandProperty InnerText | Select-String -Pattern $Pattern) {
                        Write-Verbose "Found pattern $Pattern in $UriInstance."
                        if ($InvertMatch) {
                            Write-Verbose "InvertMatch switch detected."
                            Write-Verbose "Pattern $Pattern found in $UriInstance. Uri is not healthy."
                            $Healthy=$false
                            }
                        else {
                            Write-Verbose "Pattern $Pattern found in $UriInstance. Uri is healthy."
                            $Healthy=$true
                            }
                        }
                    else {
                        if ($InvertMatch) {
                            Write-Verbose "InvertMatch switch detected."
                            Write-Verbose "Pattern $Pattern not found in $UriInstance. Uri is healthy."
                            $Healthy=$true
                            }
                        else {
                            Write-Verbose "Pattern $Pattern not found in $UriInstance. Uri is not healthy."
                            $Healthy=$false
                            }
                        }
                    }
                # If no class name was provided, search the the entire page for the provided pattern.
                else {
                    if ($WebRequest | Select-String -Pattern $Pattern) {
                        Write-Verbose "Found pattern $Pattern in $UriInstance."
                        if ($InvertMatch) {
                            Write-Verbose "$InvertMatch switch detected."
                            Write-Verbose "Pattern $Pattern found in $UriInstance. Uri is not healthy."
                            $Healthy=$false
                            }
                        else {
                            Write-Verbose "Pattern $Pattern found in $UriInstance. Uri is healthy."
                            $Healthy=$true
                            }
                        }
                    else {
                        if ($InvertMatch) {
                            Write-Verbose "InvertMatch switch detected."
                            Write-Verbose "Pattern $Pattern not found in $UriInstance. Uri is healthy."
                            $Healthy=$true
                            }
                        else {
                            Write-Verbose "Pattern $Pattern not found in $UriInstance. Uri is not healthy."
                            $Healthy=$false
                            }
                        }
                    }
                $UriHealthParameters = [ordered]@{
                    Uri = $UriInstance
                    Healthy = $Healthy
                    WebRequest = $WebRequest
                    }
                $UriHealth = New-Object -TypeName PSObject -Property $UriHealthParameters
                $UriHealth
            }
        catch {
            Write-Warning -Message $Error[0].ErrorDetails.Message
        }   
    }
        
    }
    End
    {
    }
}