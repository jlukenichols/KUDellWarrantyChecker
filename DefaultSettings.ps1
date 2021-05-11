#Set variables for Write-Log function
$LoggingMode = $true
$VerboseLogging = $true

#Define the root path of the running script
$myPSScriptRoot = "C:\Scripts\WakeOnLANFromCSV"

#Define the path to the log file
[string]$LogFilePath = "$($myPSScriptRoot)\logs\WakeOnLANFromCSV_$($currentYear)-$($currentMonth)-$($currentDay)T$($currentHour)$($currentMinute)$($currentSecond)_$($env:computername).log"

#Define the path to the CSV file containing the MAC addresses. Assumes the first line is the header line and that there is a "MACAddress" field.
$FullPathToCSV = "\\file.server\share\serviceTags.csv"

#Define your Dell warranty API key.
$DellWarrantyAPIKey = "" # Get your own from Dell TechDirect https://techdirect.dell.com/Portal/APIs.aspx