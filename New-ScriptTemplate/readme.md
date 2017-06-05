!Script-Template
===================
Here is a repository of pre-built script template for PowerShell

----------

 1. Copy this script folder and rename appropriately
 2. Rename the Verb-Driver.ps1 file appropriatly
 3. Edit the now renamed Verb-Driver.ps1 file
 4. add your custom code in the "Main Script Driver" code block

----------
How does it work
---------
**More details are available here: [Blog Post](http://vaines.org/powershell-framework/)**


The “Verb-Driver.ps1” file is the work-horse of the framework, this is the file you run to execute the script or schedule a task to run.

The driver will set up the script environment by calling functions or initializing things.

Firstly the config file will be loaded. The Config.ps1 file by default contains the log folder, naming structure and file name format, it should also contain any variables which may be used every time the script is run.

This could be done with command line arguments, however if every time I run a script I have to enter a particular argument, that’s a waste of time. If the script runs as a scheduled task, it’ll be easier to update the config file than update the scheduled task.

Secondly the Logging module is loaded and initialised, this will trigger the log folder to be created and a log file to be created. If the folder and log file already exist the log file will be appended.

Next, any other modules should be loaded (in the template’s default state the “Sample-Functions.ps1”).

If any of these three sections are to fail for any reason they script will terminate and to avoid causing any potential damage.

Once the script is initialised and ready to perform custom actions the main script block can be run, safe in the knowledge that modules are loaded, the script is logging and config files are loaded.

The main script block is where the specific code for the project/tasks goes, this may be processing data from the config file, processing CSV files and other data and exporting some sort of result.

When writing a main script block use the following structure to write messages to the log file.

    Log-write -logpath $Script:LogPath -linevalue “A message”

In it’s default state these messages will be written out to console as well as the file. This can be altered in the config file by changing the 

    $Script:LoggingDebug” variable to $false

The resultant log file will look something like this:

The output on the PowerShell console will show the same information

Once the Main script block has completed, any session variables will be cleaned up and the log file finished off.
