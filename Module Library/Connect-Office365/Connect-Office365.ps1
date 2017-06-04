<# 
    .SYNOPSIS 
    Office 365 connection modules

    .DESCRIPTION 
    Prompts a user to enter username and password to connect to office 365 tenant
        
    .EXAMPLE 
        #Connect to all Office 365 services:
            Connect-Office365
                write-host "Do Some Stuff with Exchange, Skype and Security & Compliance"
            Disconnect-Office365

    .EXAMPLE
    #Connect to individual services:
            Connect-SFBOnline
                write-host "Do Some Skype For Business stuff"
                Disconnect-SFBOnline
            Connect-ExOnline
                write-host "Do Some Exchange stuff"
            Disconnect-ExOnline
            Connect-SCCOnline
                write-host "Do Some Stuff with Security & Compliance"
            Disconnect-SCCOnline

#>



Function Get-O365Credentials {
    <# 
        .SYNOPSIS
            Requests user for Office 365 credentials

        .DESCRIPTION
            Requests user for Office 365 credentials is calles as a subfunction of other functions in this module, do not call manually
        .PARAMETER Force
            -Force [boolean]
                override the check for credentials currently being set, used incase credentials are invalid

        .EXAMPLE
            ...
            write-host "Password incorrect"
            Get-O365Credentials -force $true
    #>
     [CmdletBinding()]Param (
        [Parameter(Mandatory=$false)][boolean]$force
    )
    #This function will be called a few times,
    #Check to see if it has already been entered or the request if forced (eg. bad password check)
    if(($force -eq $true) -or ($script:Credentials -eq $null)){
        Log-write -logpath $Script:LogPath -linevalue "`t`tEnter your Office 365 admin credentials"
        $script:Credentials = Get-Credential -Message "Enter your Office 365 admin credentials"
    }#endif
} #end function


Function Connect-MSOL{
    <# 
        .SYNOPSIS 
            Checks the MSOL session is connected

        .DESCRIPTION 
            Checks the MSOL session is connected and connects it if not
            Also checks to ensure the "credentials" are currently stored in the 'script:' variable scope
        
        .EXAMPLE 
            if(Connect-MSOL){write-host "MSOL is connected"}
        
    #>
    begin{    

        $CurrentMSOLStatus = Get-MsolDomain -ErrorAction SilentlyContinue
    }
    process{
        if($CurrentMSOLStatus){
        #The MSOL may be connected but the credentials may be clear, check this is not the case
        #The other functions in this module use this function to confirm the credentials and MSOL exist/connect
        If ($script:Credentials -eq $null){
            Get-O365Credentials
        }

        #MSOL is already connected, no need for output clutter
        return $true #MSOL is connected

        } else {
            Log-write -logpath $Script:LogPath -linevalue "`tConnecting to Microsoft Online (MSOL)"
            try{
                
                #Users credentials may be invalid so try to connect 3 times, any more risks
                #locking the users account.
                $i=0 #Start a counter
                Do {
                    #Check the connect sequence has run less than 3 times
                    if ($i -ge 3){
                        Log-write -logpath $Script:LogPath -linevalue "`t`tThe 3rd login attempt has failed, aborting script to avoid account lockout"
                        throw #cause an error, go to the catch statement
                    }

                    #Attempt to connect to MSOL
                    Connect-MsolService -Credential $script:Credentials -ErrorAction SilentlyContinue -ErrorVariable ProcessError
                    $CurrentMSOLStatus = Get-MsolDomain -ErrorAction SilentlyContinue #See if the MSOL is connected by listing the MSOLDomains

                    if($CurrentMSOLStatus){
                        #If the domain list isnt empty MSOL is connected
                        Log-write -logpath $Script:LogPath -linevalue "`t`tMSOL connected"
                        $i = 4
                    } else {
                        #If the domain list is empty MSOL is not connected
                        #Request the credentials again, with force set to true as the credentials variable
                        #is not currently empty, it's just didnt connect, then add 1 (++) to the counter
                        Log-write -logpath $Script:LogPath -linevalue "`t`tCredentials invalid, please try again"
                        Get-O365Credentials -force $true
                        $i ++
                    }
                } Until ($CurrentMSOLStatus) #If the MSOL is connected the 'do' loop doesnt need to continue

                return $true #MSOL is connected
                
            }catch{
                Log-Error -LogPath $Script:LogPath -ErrorDesc "Failed to connect to MSOL,check 'Microsoft Online Service Sign-in Assistant for IT Professionals' is installed`n`t$_.Exception" -ExitGracefully $True
            }
        }#EndProcess
    }#EndIf
}#EndFunction


Function Connect-SFBOnline{
    <# 
        .SYNOPSIS 
            Starts a Skype for business sessions

        .DESCRIPTION 
            Checks user is running script as an admin, checks the WinRM service is running and then connects to the Skype for business service.
            Will check MSOL is connected and credentials are valid too
        
        .EXAMPLE 
            Connect-SFBOnline
        
    #>
    begin{
        Log-write -logpath $Script:LogPath -linevalue "`tConnecting to Skype For Business Online"

        #The Skype for business module only seems to work if you run script as admin
        If(([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){
            #Returns true if script is running in admin context
        }else{
            Log-Error -LogPath $Script:LogPath -ErrorDesc "Please run this script with administrator privileges" -ExitGracefully $True
        }


        if(Connect-MSOL){
            #If MSOL is connected or connects, nothing to do
        }else{
            #If MSOL fails to connect, the Connect-MSOL module will show the nessessary output
            #Throw an error and abort the script
            Log-Error -LogPath $Script:LogPath -ErrorDesc "$_.Exception" -ExitGracefully $True
        }  
    }
    Process{
        try{
            if (get-module -list SkypeOnlineConnector){
                Import-Module SkypeOnlineConnector
                Log-write -logpath $Script:LogPath -linevalue "`t`tSkypeOnlineConnector module loaded"

            }else{
                log-Error -LogPath $Script:LogPath -ErrorDesc "SkypeOnlineConnector module not found`nCheck 'Skype for Business Online, Windows PowerShell Module' is installed" -ExitGracefully $True
            }

            #The Skype module will need the WinRM module to be running
            if ((get-service winrm).status -ne "Running"){
                 Log-write -logpath $Script:LogPath -linevalue "`t`t`tThe WinRM service is not running, attempting to start..."
                 try{
                     start-service winrm
                 }catch{    
                    Log-write -logpath $Script:LogPath -linevalue "`t`t`tUnable to start, trying as administrator..."
                    #Failed to start, assume the user isnt an admin or hasnt run script as admin
                    #Prompt to run the script as an admin user
                    try {
                        Start-Process powershell -Verb runAs -ArgumentList "start-service winrm" -Wait
                        #Check to see if the service is now running
                        if ((get-service winrm).status -ne "Running"){
                            log-Error -LogPath $Script:LogPath -ErrorDesc "Unable to start the WinRM service, please start manually" -ExitGracefully $True
                        } else {
                            Log-write -logpath $Script:LogPath -linevalue "`t`tWinRM service started"
                        }
                    } catch {
                        
                    }#EndCatch
                 }#EndCatch
            }#EndIf (WinRM)


            Log-write -logpath $Script:LogPath -linevalue "`tCreating Skypesession"

            #MSOL is connected so we can assume this session has valid O365 credentials stored as $Script:Credentials
            #Attempt to connect
            $script:sfboSession = New-CsOnlineSession -Credential $script:Credentials
            Import-PSSession $script:sfboSession -DisableNameChecking | Out-Null

        }catch{
            Log-Error -LogPath $Script:LogPath -ErrorDesc "Failed to connect to Skype For Business Online`n$_.Exception" -ExitGracefully $True
        }#EndTry
    }#EndProcess
}#EndFunction

Function Disconnect-SFBOnline{
    <# 
        .SYNOPSIS 
            Disconnects a Skype for business sessions

        .DESCRIPTION 
            Checks for and disconnects a Skype for business session
                   
        .EXAMPLE 
            disconnect-SFBOnline
        
    #>
    try{
        # Logic to confirm if the Exchange online session has been disconnected.
        If ($script:sfboSession -eq $null) {
            Log-write -logpath $Script:LogPath -linevalue "No Skype For Business Online session found"
        }
        Else {
            Remove-PSSession $script:sfboSession
            If ($script:sfboSession.State -eq "Closed") {
                Log-write -logpath $Script:LogPath -linevalue "Skype For Business Online session closed"
            }
            ElseIf ($script:sfboSession.state -eq "Open") {
                Log-Error -LogPath $Script:LogPath -ErrorDesc "Skype For Business Online session did not close" -ExitGracefully $false
            }
        }
    }catch{
        Log-Error -LogPath $Script:LogPath -ErrorDesc "Failed to close the Skype For Business Online session" -ExitGracefully $True
    }#EndTry
}#EndFunction






Function Connect-ExOnline{
    <# 
        .SYNOPSIS 
            Starts a Exchange online sessions

        .DESCRIPTION 
            Checks user is running script as an admin, checks the WinRM service is running and then connects to the Exchange online service.
            Will check MSOL is connected and credentials are valid too
        
        .EXAMPLE 
            Connect-ExOnline
        
    #>
    begin{
        if(Connect-MSOL){
            #If MSOL is connected or connects, nothing to do
        }else{
            #If MSOL fails to connect, the Connect-MSOL module will show the nessessary output
            #Throw an error and abort the script
            Log-Error -LogPath $Script:LogPath -ErrorDesc "$_.Exception" -ExitGracefully $True
        }  

        Log-write -logpath $Script:LogPath -linevalue "`tConnecting to Exchange Online"
 
    }
    Process{
        try{
            Log-write -logpath $Script:LogPath -linevalue "`t`tCreating Session"

            #MSOL is connected so we can assume this session has valid O365 credentials stored as $Script:Credentials
            #Attempt to connect
            $script:exoSession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri "https://outlook.office365.com/powershell-liveid/" -Credential $script:Credentials -Authentication "Basic" -AllowRedirection

            Import-PSSession $script:exoSession -DisableNameChecking | Out-Null

            Log-write -logpath $Script:LogPath -linevalue "`t`tConnected to Exchange Online"
 
        }catch{
            Log-Error -LogPath $Script:LogPath -ErrorDesc "Failed to connect to Exchange Online`n$_.Exception" -ExitGracefully $True
        }#EndTry
    }#EndProcess
}#EndFunction

Function Disconnect-ExOnline{
    <# 
        .SYNOPSIS 
            Disconnects a Exchange sessions

        .DESCRIPTION 
            Checks for and disconnects a Exchange session
                   
        .EXAMPLE 
            disconnect-ExOnline
        
    #>
    try{
        # Logic to confirm if the Exchange online session has been disconnected.
        If ($script:exoSession -eq $null) {
            Log-write -logpath $Script:LogPath -linevalue "No Exchange session found"
        }
        Else {
            Remove-PSSession $script:exoSession
            If ($script:exoSession.State -eq "Closed") {
                Log-write -logpath $Script:LogPath -linevalue "Exchange Online session closed"
            }
            ElseIf ($script:exoSession.state -eq "Open") {
                Log-Error -LogPath $Script:LogPath -ErrorDesc "Exchange Online session did not close" -ExitGracefully $false
            }
        }
    }catch{
        Log-Error -LogPath $Script:LogPath -ErrorDesc "Failed to close the Exchange Online session" -ExitGracefully $True
    }#EndTry
}#EndFunction




Function Connect-SCCOnline{
    <# 
        .SYNOPSIS 
            Starts a Security & Compliance Center session

        .DESCRIPTION 
            Connects to the Security & Compliance Center service.
            Will check MSOL is connected and credentials are valid too
        
        .EXAMPLE 
            Connect-SCCOnline
        
    #>
    begin{
        if(Connect-MSOL){
            #If MSOL is connected or connects, nothing to do
        }else{
            #If MSOL fails to connect, the Connect-MSOL module will show the nessessary output
            #Throw an error and abort the script
            Log-Error -LogPath $Script:LogPath -ErrorDesc "$_.Exception" -ExitGracefully $True
        }  

        Log-write -logpath $Script:LogPath -linevalue "`tConnecting to Security & Compliance Center Online"
 
    }
    Process{
        try{
            Log-write -logpath $Script:LogPath -linevalue "`t`tCreating Session"

            #MSOL is connected so we can assume this session has valid O365 credentials stored as $Script:Credentials
            #Attempt to connect
            $script:sccoSession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://ps.compliance.protection.outlook.com/powershell-liveid/ -Credential $script:Credentials -Authentication "Basic" -AllowRedirection

            Import-PSSession $script:sccoSession -Prefix cc -DisableNameChecking | Out-Null

            Log-write -logpath $Script:LogPath -linevalue "`t`tConnected to Security & Compliance Center Online"
 
        }catch{
            Log-Error -LogPath $Script:LogPath -ErrorDesc "Failed to connect to Security & Compliance Center Online`n$_.Exception" -ExitGracefully $True
        }#EndTry
    }#EndProcess
}#EndFunction

Function Disconnect-SCCOnline{
    <# 
        .SYNOPSIS 
            Disconnects a Security & Compliance Center sessions

        .DESCRIPTION 
            Checks for and disconnects a Security & Compliance Center session
                   
        .EXAMPLE 
            disconnect-SCCOnline
        
    #>
    try{
        # Logic to confirm if the Security & Compliance Center online session has been disconnected.
        If ($script:sccoSession -eq $null) {
            Log-write -logpath $Script:LogPath -linevalue "No Security & Compliance Center Online session found"
        }
        Else {
            Remove-PSSession $script:sccoSession
            If ($script:sccoSession.State -eq "Closed") {
                Log-write -logpath $Script:LogPath -linevalue "Security & Compliance Center Online session closed"
            }
            ElseIf ($script:sccoSession.state -eq "Open") {
                Log-Error -LogPath $Script:LogPath -ErrorDesc "Security & Compliance Center Online session did not close" -ExitGracefully $false
            }
        }
    }catch{
        Log-Error -LogPath $Script:LogPath -ErrorDesc "Failed to close the Security & Compliance Center Online session" -ExitGracefully $True
    }#EndTry
}#EndFunction




Function Connect-Office365{
    <# 
        .SYNOPSIS 
            Starts a session for Skype for business, Exchange online and the Security & Compliance Center sessions

        .DESCRIPTION 
            Checks user is running script as an admin, checks the WinRM service is running and then connects to the Skype for business service.
            Will check MSOL is connected and credentials are valid too
        
        .EXAMPLE 
            Connect-SFBOnline
        
    #>
    try{
        Connect-MSOL #Not strictly nessessary as the other 2 will call this module, but this is the proper order

        Connect-SFBOnline
  
        Connect-ExOnline

        Connect-SCCOnline
               
    }catch{
        Log-Error -LogPath $Script:LogPath -ErrorDesc "Failed to Connect to Office 365, please review logs" -ExitGracefully $True
    }#EndTry
}#EndFunction


Function Disconnect-Office365{
    <# 
        .SYNOPSIS 
            Disconnects a Skype for business sessions

        .DESCRIPTION 
            Checks for and disconnects a Skype for business session
                   
        .EXAMPLE 
            disconnect-SFBOnline
        
    #>
    try{

        Disconnect-SFBOnline
  
        Disconnect-ExOnline

        Disconnect-SCCOnline

        $script:credentials = $null
                
    }catch{
        Log-Error -LogPath $Script:LogPath -ErrorDesc "Failed to disconnect to Office 365, please review logs" -ExitGracefully $True
    }#EndTry
}#EndFunction
