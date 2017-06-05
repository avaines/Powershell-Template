<#
.SYNOPSIS
    Test Functions

.DESCRIPTION
    A set of functions to test various features

 #>

Function Test-Function1 { 
    <#
        .DESCRIPTION
            Accepts a string and prefixes it with "You Entered: " before returning it

        .PARAMETER  MyParam
                Accepts a string
        
        .EXAMPLE
            $MyVar = Test-Function1 "Rain"
            write-host $MyVar
                PS C:\> "You Entered: Rain"  
    #>

[CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)][string]$MyParam
    )

    Begin {
        Log-write -logpath "$Script:LogPath" -linevalue "`tStarting Test-Function1"

    }

    Process{
        
        try{

            Log-write -logpath "$Script:LogPath" -linevalue "`t`tProcessing $MyParam"
            $MyReturn = "You entered: $MyParam"

            return $MyReturn

        }catch{

            Log-write -logpath $Script:LogPath -linevalue "`t`tGet-shares: [ERROR] $_.exceptionmessage"

        }# Try/Catch
    }# Process
    End{
        
        Log-write -logpath "$Script:LogPath" -linevalue "`tExiting Test-Function1"

    }# End
}# Function