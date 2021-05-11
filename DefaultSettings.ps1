#You can modify this file or create your own CustomSettings.ps1 file.
#If CustomSettings.ps1 exists then it will be read instead of this file.

#Set variables for Write-Log function
$LoggingMode = $true #Setting this to $false will prevent all logging
$VerboseLogging = $true #Setting this to $true will output log strings to both the console and the log file

#Define the root path of the running script
$myPSScriptRoot = "C:\Scripts\WakeOnLANFromCSV"

#Define the path to the log file
[string]$LogFilePath = "$($myPSScriptRoot)\logs\WakeOnLANFromCSV_$($currentYear)-$($currentMonth)-$($currentDay)T$($currentHour)$($currentMinute)$($currentSecond)_$($env:computername).log"

#Define the path to the CSV file containing the Dell service tags.
#Assumes the first line is the header line, there is a "Computer Name" field, and there is a "Computer Serial Number" field containing the Dell service tag.
#Can contain extra fields but they will be ignored.
#Can be a UNC path.
$FullPathToInputCSV = "$($myPSScriptRoot)\ExampleInput.CSV"

#Define the path to the CSV file where you will output the warranty data.
#Can be a UNC path.
$FullPathToOutputCSV = "$($myPSScriptRoot)\DellWarrantyData.CSV"

#Define your Dell warranty API project name. This will be the "client_id" when you generate your token.
$DellWarrantyProjectName = "" # Create your own in Dell TechDirect https://techdirect.dell.com/Portal/APIs.aspx If you run into issues email APIs_TechDirect@dell.com

#Define your Dell warranty API key. This will be the "client_id" when you generate your token.
$DellWarrantyAPIKey = "" # Get your own from Dell TechDirect https://techdirect.dell.com/Portal/APIs.aspx If you run into issues email APIs_TechDirect@dell.com