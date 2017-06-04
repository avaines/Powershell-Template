<#
.SYNOPSIS
    AD Comms via RSAT-AD

.DESCRIPTION
    Connects and disconnects from AD with RSAT

.SYNTAX  
    For MSOL dotsource this module and call the functions like
    . "Modules/Connect-AD.ps1"
   
     
.NOTES
    This module requires the Logging Module be pre-loaded to accept the "Log-Write" calls

 #>

 Function Connect-AD { 
 Log-write -logpath $Script:LogPath -linevalue "`tChecking for ActiveDirectory Module"

     If ((Get-module -Name activedirectory -ErrorAction SilentlyContinue) -eq $null) {
     
        Log-write -logpath $Script:LogPath -linevalue "`t`tActiveDirectory module not loaded, attempting to add..."
         try {
            import-module activedirectory -ErrorAction SilentlyContinue
            while ((get-module -listAvailable -Name ActiveDirectory) -eq $null) {
               Log-Error -LogPath $Script:LogPath -ErrorDesc "Unable to ActiveDirectory module, check RSAT is installed" -ExitGracefully $True
               import-module activedirectory -ErrorAction SilentlyContinue

            }

         } catch {
            Log-Error -LogPath $Script:LogPath -ErrorDesc "$_.exceptionmessage" -ExitGracefully $True
         }

    } else {
        Log-Error -LogPath $Script:LogPath -ErrorDesc "ActiveDirectory module is already loaded" -ExitGracefully $True
    }


}

