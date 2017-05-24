<#
.SYNOPSIS
    Config file

.DESCRIPTION
    This config file contains variables which may affect functionality of the script.

    Where possible try restrict variables in here to the $SCRIPT: scope
 #>

#Variables for the logging module
$Script:LoggingDebug = $true #Causes debug output to console when true, uses Write-Host, don't enable for production
$Script:LogFolder = "Logs"
$Script:LogPath = "$Script:LogFolder\Log-$(get-date -f yyyy-MM-dd).log"  #Set log path


