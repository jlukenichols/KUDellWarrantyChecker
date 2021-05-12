#You can modify this file or create your own CustomSettings.ps1 file.
#If CustomSettings.ps1 exists then it will be read instead of this file.

#Set variables for Write-Log function
$LoggingMode = $true #Setting this to $false will prevent all logging
$VerboseLogging = $true #Setting this to $true will output log strings to both the console and the log file

#Define the root path of the running script
$myPSScriptRoot = $PSScriptRoot

#Define the path to the log file
[string]$LogFilePath = "$($myPSScriptRoot)\logs\KUDellWarrantyChecker_$($currentYear)-$($currentMonth)-$($currentDay)T$($currentHour)$($currentMinute)$($currentSecond)_$($env:computername).log"

#Define the path to the CSV file containing the Dell service tags.
#Assumes the first line is the header line, there is a "Computer Name" field, and there is a "Computer Serial Number" field containing the Dell service tag.
#Can contain extra fields but they will be ignored.
#Can be a UNC path.
$FullPathToInputCSV = "$($myPSScriptRoot)\ExampleInput.CSV"

#Define the path to the CSV file where you will output the warranty data.
#Can be a UNC path.
$FullPathToOutputCSV = "$($myPSScriptRoot)\DellWarrantyData.CSV"

#Define your Dell warranty API key. This will be the "client_id" when you generate your token.
$DellWarrantyAPIKey = "" # Get your own from Dell TechDirect https://techdirect.dell.com/Portal/APIs.aspx If you run into issues email APIs_TechDirect@dell.com

#Define your Dell warranty API key secret. This will be the "client_secret" when you generate your token.
$DellWarrantyAPIKeySecret = "" # Get your own from Dell TechDirect https://techdirect.dell.com/Portal/APIs.aspx If you run into issues email APIs_TechDirect@dell.com

#Define the name of your PDQ Inventory custom field that will store the "Ship Date" field from the API query.
#This assumes you have already created the custom field with the date/time data type.
$ShipDateCustomFieldName = "Purchase Date"

#Define the name of your PDQ Inventory custom field that will store the entitlement end date from the API query
#This assumes you have already created the custom field with the date/time data type.
$EntitlementEndDateCustomFieldName = "Warranty End Date"

#Define the path to your PDQ Inventory database.
$DBPath = "C:\programdata\Admin Arsenal\PDQ Inventory\Database.db"

#Define the path to sqlite3.exe
$sqlite = "C:\Program Files (x86)\Admin Arsenal\PDQ Inventory\sqlite3.exe"

#Define the path to PDQInventory.exe
$PDQInvExecPath = "C:\Program Files (x86)\Admin Arsenal\PDQ Inventory\PDQInventory.exe"

#Define headers for output CSV file
$OutputCSVHeaderLine = "Computer Name,$ShipDateCustomFieldName,$EntitlementEndDateCustomFieldName"

#TODO: Organize the settings more logically