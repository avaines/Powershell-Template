<#
.SYNOPSIS
    Test Functions

.DESCRIPTION
    A set of functions to test various features

 #>




### Test-Function1 ###
<#
	.DESCRIPTION
		Accepts a string and prefixes it with "Not " before returning it

	.PARAMETER  MyParam
			Accepts a string
	 
	.EXAMPLE
        $MyVar = Test-Function1 "Rain"
		write-host $MyVar
            PS C:\> "Not Rain"  
#>

Function Test-Function1 { 
[CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)][string]$MyParam
    )

    Begin {
        Log-write -logpath "$Script:LogPath" -linevalue "`tStarting Test-Function1"
        
        $myArray =@()

    }

    Process{
        
        try{

            Log-write -logpath "$Script:LogPath" -linevalue "`t`tProcessing $MyParam"
            $MyReturn = "Not $MyParam"

            return $MyReturn

        }catch{

            Log-write -logpath $Script:LogPath -linevalue "`t`tGet-shares: [ERROR] $_.exceptionmessage"

        }#Try/Catch
    }#Process
    End{
        
        Log-write -logpath "$Script:LogPath" -linevalue "`tExiting Test-Function1"

    }#End
}#Function