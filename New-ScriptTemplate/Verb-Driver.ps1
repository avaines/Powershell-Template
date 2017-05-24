<#
.SYNOPSIS
    Overview of script

.DESCRIPTION
    Brief description of script

.PARAMETER  Param
    Brief description of parameter input required, repeat this section as required
     
.NOTES
    Author:     Aiden Vaines
    Purpose:    Script Template
    
    Date        Change
    10/5/17     Basic template structure implemented
    24//517     Now automatically loads any modules in the "Modules" folder

 #>
 
 [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)][string]$AParam
 
    )

#Load modules and related files
try{ 
    #DotSource the configfile
    . ".\Config.ps1" 

    #Logging:
    #Load the logging module and set the login path so al the other scripts use it
    . ".\Modules\Init-Logging.ps1"
    
    #Initialize the log
    Log-Start -logpath $Script:LogPath

    #Load the other modules in the module folder (except the Logging module as that is already loaded)
    $Modules = Get-ChildItem ".\Modules\" | Where-Object {$_.name -ne "Init-Logging.ps1"}
    
    foreach ($Module in $Modules){  
        $ModuleName = $Module.Name
        Log-write -logpath $Script:LogPath -linevalue "Loading Module: $ModuleName"
        . ".\Modules\$ModuleName"
    }

}catch{ 

    Log-Error -LogPath $Script:LogPath -ErrorDesc $_.Exception -ExitGracefully $True

}


try{

    #####################################
    # MAIN SCRIPT BLOCK BEGINS HERE.....#
    #####################################




    $MyVar = Test-function1 $Param
    Log-write -logpath $Script:LogPath -linevalue "Result:`t$MyVar"
    



    #####################
    #.....AND ENDS HERE #
    #####################

    Log-Finish -LogPath $Script:LogPath #-NoExit $True
    #Cleanup from any previous runs
    Remove-Variable * -ErrorAction SilentlyContinue

}catch{

    Log-Error -LogPath $Script:LogPath -ErrorDesc "$_.Exception" -ExitGracefully $True

}#Try/Catch

#Cleanup from any previous runs
Remove-Variable * -ErrorAction SilentlyContinue
