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
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)][string]$Word
 
    )

# Load modules and related files
try{ 
    # Create a list of system Variables already in place before running the script,
    # Will be used to clear any session variables
    $SystemVars = Get-Variable | Where-Object{$_.Name}
    
    # 'cd' to execution dir
    Set-Location (Split-Path -Path $MyInvocation.MyCommand.Definition -Parent)

    # DotSource the configfile
    . ".\Config.ps1" 

    ########
    # Logging:
    # Load the logging module and set the log path so all the other scripts use it
    . ".\Modules\Init-Logging.ps1"
    
    # Initialize the log
    Start-Log
    ########

    # Load the other modules in the module folder (except the Logging module as that is already loaded)
    ##############
    $Modules = Get-ChildItem ".\Modules\" | Where-Object {$_.name -ne "Init-Logging.ps1"}
    
    foreach ($Module in $ScriptModules){  
        $ModuleName = $Module.Name
        Write-Log -linevalue "Loading Module: $ModuleName"
        . ".\Modules\$ModuleName"
    }

    #Import or attempt to install modules available from the public powershell gallery as specified in the config file
    foreach($RequiredModule in $Script:RequiredModules) {
        if(!(get-module -name $RequiredModules)){
            $AvailableModules = Get-Module -ListAvailable | where { $_.name -eq $RequiredModules}
            if($AvailableModules){
                write-host "$RequiredModules found, attempting to import"
                try{
                    Import-Module $RequiredModules -ErrorAction SilentlyContinue
                    write-Log -linevalue "$RequiredModules imported" -level "MODULES"                    
                }catch{
                    Write-Error -ErrorDesc $_.Exception -ExitGracefully $True
                }
            }else{
                write-host "$RequiredModules not found, attempting to install"
                try{
                    Install-Module -Name ReportHTML
                    write-Log -linevalue "$RequiredModules Installed" -level "MODULES"
                }catch{
                    Write-Error -ErrorDesc $_.Exception -ExitGracefully $True
                }
            }#end import
        }#end if get modules
    }#end foreach

    
}catch{ 

    Write-Error -ErrorDesc $_.Exception -ExitGracefully $True

}


try{

    #####################################
    # MAIN SCRIPT BLOCK BEGINS HERE.....#
    #####################################




    $MyVar = Test-function1 $Word
     Write-Log -linevalue "Result:`t$MyVar"
    



    #####################
    #.....AND ENDS HERE #
    #####################
   
}catch{

    Write-Error -ErrorDesc "$_.Exception" -ExitGracefully $True

} finally {
    
    # Cleanup from any previous runs
    Stop-Log -NoExit $True
    
    Get-Variable | Where-Object { $SystemVars -notcontains $_.Name } | Where-Object { Remove-Variable -Name “$($_.Name)” -Force -Scope “global” -ErrorAction SilentlyContinue}
    
} # Try/Catch
