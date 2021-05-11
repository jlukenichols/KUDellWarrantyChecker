Clear-Host

<#
.SYNOPSIS
  Name: KUDellWarrantyChecker.ps1
  The purpose of this script is to ingest a CSV file containing Dell service tags, perform a Dell API lookup to grab their warranty data, then import that data into PDQ Inventory
  
.DESCRIPTION
  See synopsis

.NOTES
    Release Date: 2021-05-11T13:01
    Last Updated: 2021-05-11T13:01
   
    Author: Luke Nichols
    Github link: https://github.com/jlukenichols/KUDellWarrantyChecker

.EXAMPLE
    Just run the script without parameters, it's not designed to be called like a function
#>

#-------------------------- Begin defining functions --------------------------

# Dot-source function for writing to log file
. .\functions\Write-Log.ps1

#-------------------------- End defining functions --------------------------

#-------------------------- Set any initial values --------------------------
$ScriptExecutionDate = Get-Date

#Grab the individual portions of the date and put them in vars
[DateTime]$currentDate=Get-Date
$currentYear = $($currentDate.Year)
$currentMonth = $($currentDate.Month).ToString("00")
$currentDay = $($currentDate.Day).ToString("00")

$currentHour = $($currentDate.Hour).ToString("00")
$currentMinute = $($currentDate.Minute).ToString("00")
$currentSecond = $($currentDate.Second).ToString("00")

#Set variables for write-log function
$LoggingMode = $true
$VerboseLogging = $true

#Define the root path of the running script
$myPSScriptRoot = "C:\Scripts\WakeOnLANFromCSV"

#Define the path to the log file
[string]$LogFilePath = "$($myPSScriptRoot)\logs\KUDellWarrantyChecker_$($currentYear)-$($currentMonth)-$($currentDay)T$($currentHour)$($currentMinute)$($currentSecond)_$($env:computername).log"

#Dot-source settings file
if (Test-Path .\CustomSettings.ps1) {
    . .\CustomSettings.ps1
    $LogMessage = "Importing settings from CustomSettings.ps1"
} else {
    . .\DefaultSettings.ps1
    $LogMessage = "Importing settings from DefaultSettings.ps1"
}

#Define the path to the CSV file containing the MAC addresses. Assumes the first line is the header line and that there is a "MACAddress" field.
#$FullPathToCSV = "\\kuit.ku.kettering.edu\itstuff\Software\PDQ_Deploy_Repo\Reports\MacAddrOn620\MAC Addresses on 620 VLAN.csv"

#-------------------------- End setting initial values --------------------------

#-------------------------- Start main script body --------------------------

#-------------------------- End main script body --------------------------