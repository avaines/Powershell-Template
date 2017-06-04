Connect-O365
-------------
Contains a suite of functions for connecting to office 365 powershell services

Connect to individual services:
	
~~~~
	Connect-SFBOnline
		write-host "Do Some Skype For Business stuff"
		Disconnect-SFBOnline
	Connect-ExOnline
		write-host "Do Some Exchange stuff"
	Disconnect-ExOnline
	Connect-SCCOnline
		write-host "Do Some Stuff with Security & Compliance"
	Disconnect-SCCOnline	
~~~~

or connect to all of them
~~~~
	Connect-Office365
		write-host "Do Some Stuff with Exchange, Skype and Security & Compliance"
	Disconnect-Office365
~~~~

> **Note:**
> The Skype for Business/Lync module seems to only work if run as administrator, 
> The user context is checked and the script will abort if its not got admin rights




