<#
.SYNOPSIS
  Name: KUDellWarrantyChecker.ps1
  The purpose of this script is to ingest a CSV file containing Dell service tags, perform a Dell API lookup to grab their warranty data, then import that data into PDQ Inventory
  
.DESCRIPTION
  See synopsis

.NOTES
    Release Date: 2021-05-11T13:01
    Last Updated: 2022-07-07T10:18
   
    Author: Luke Nichols
    Github link: https://github.com/jlukenichols/KUDellWarrantyChecker

.EXAMPLE
    Just run the script without parameters, it's not designed to be called like a function.
    Make sure the user that you run the script as has permissions to read your input CSV file and also is a member of the console users in PDQ Inventory
#>

#-------------------------- Set any initial values --------------------------

#Clear the console for easier PowerShell ISE debugging
Clear-Host

#This is required because you will get a TLS error otherwise. I think Invoke-RestMethod uses TLS 1.0 by default or something.
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 # https://stackoverflow.com/questions/41618766/powershell-invoke-webrequest-fails-with-ssl-tls-secure-channel
#Required for the API lookups, not sure why.
Add-Type -AssemblyName System.Web # https://www.undocumented-features.com/2020/06/30/powershell-oauth-authentication-two-ways/
#Get the path of the running script
$MyPSScriptRoot = $MyInvocation.MyCommand.Path
$MyPSScriptRoot = Split-Path $MyPSScriptRoot -Parent
#Change the working directory to the script root to fix issues with invalid file references after elevating
Set-Location -Path $MyPSScriptRoot

$ScriptExecutionDate = Get-Date

#Grab the individual portions of the date and put them in vars
[DateTime]$currentDate=Get-Date
$currentYear = $($currentDate.Year)
$currentMonth = $($currentDate.Month).ToString("00")
$currentDay = $($currentDate.Day).ToString("00")

$currentHour = $($currentDate.Hour).ToString("00")
$currentMinute = $($currentDate.Minute).ToString("00")
$currentSecond = $($currentDate.Second).ToString("00")

#Dot-source default settings file
. .\DefaultSettings.ps1
#Dot-source custom settings file if it exists. This will overwrite any duplicate values from DefaultSettings.ps1
if (Test-Path .\CustomSettings.ps1) {
    . .\CustomSettings.ps1
    
}

#-------------------------- End setting initial values --------------------------

#-------------------------- Begin defining functions --------------------------

#Change working directory
cd $myPSScriptRoot

# Dot-source functions for writing to log files
. .\functions\Write-Log.ps1

# Function for generating Dell API auth token
Function Get-AuthToken {
    #Mostly taken from https://www.undocumented-features.com/2020/06/30/powershell-oauth-authentication-two-ways/ but adapted to the Dell API
    Param (
        [string]$clientID,
        [string]$clientSecret
    )

    $requestAccessTokenUri = "https://apigtwb2c.us.dell.com/auth/oauth/v2/token" # Production Endpoint    
    $body = "client_id=$($clientID)&client_secret=$($clientSecret)&grant_type=client_credentials"
    $contentType = "application/x-www-form-urlencoded"
    try {
        #Retrieve token
        $Auth = Invoke-WebRequest "$($requestAccessTokenUri)?client_id=$($clientID)&client_secret=$($clientSecret)&grant_type=client_credentials" -Method Post -UseBasicParsing #https://www.powershellgallery.com/packages/Get-DellWarranty/2.0.0.0

        #Convert result from JSON to PS object
        $Auth = ($Auth | ConvertFrom-Json)

        $script:AuthenticationResult = $Auth.access_token
        $script:TokenExpiration = (get-date).AddSeconds($Auth.expires_in)
    } catch {
        throw
    }
}

# Function for retrieving Dell warranty data using token from Get-AuthToken
Function Retrieve-WarrantyData {
    Param (
        [string]$AuthToken,
        [string]$DellSvcTag
    )

    $warrantyCheckUri = "https://apigtwb2c.us.dell.com/PROD/sbil/eapi/v5/asset-entitlements"
    $headers = @{
        'Authorization' = "Bearer $AuthToken"
    }
    $parameters = @{
        'servicetags' = $DellSvcTag
    }
    
    try {
        $APIResults = Invoke-RestMethod -Uri $warrantyCheckUri -Headers $headers -Body $parameters -Method GET
        $APIResults = ($APIResults | ConvertTo-Json | ConvertFrom-Json)
        return $APIResults
    } catch {
        throw
    }
}

#-------------------------- End defining functions --------------------------

#-------------------------- Start main script body --------------------------

#Clean out old log files
Delete-OldFiles -NumberOfDays $LogRotationIntervalInDays -PathToLogs "$($myPSScriptRoot)\logs"

#Start the log file
Write-Log $LogMessage

#Show the path to the input file in the log
$LogMessage = "FullPathToInputCSV: $FullPathToInputCSV"
Write-Log $LogMessage

$LogMessage = "Checking if `$TokenExpiration $TokenExpiration is less than $(Get-Date)"
Write-Log $LogMessage

#Get auth token. Lasts for 3600 seconds.
if ($TokenExpiration -lt (Get-Date)) {
    #Token is expired. Get a new one.
    $LogMessage = "Generating new auth token..."
    Write-Log $LogMessage
    Get-AuthToken -clientID $DellWarrantyAPIKey -clientSecret $DellWarrantyAPIKeySecret #token is written to $AuthenticationResult within the function
} else {
    #Token is still valid. Keep using it.
    $LogMessage = "Found previously generated auth token that is still valid."
    Write-Log $LogMessage
}

#TODO: Fix this in the log. $Auth.expires_in appears to be empty.
$LogMessage = "`$Auth.expires_in: $($Auth.expires_in)"
Write-Log $LogMessage

#TODO: Wrap this into a function

$LogMessage = "Creating new output file at $FullPathToOutputCSV"
Write-Log $LogMessage
#Delete file if it already exists before proceeding to clear permissions
if (Test-Path $FullPathToOutputCSV) {
    Remove-Item -Path $FullPathToOutputCSV -Force
}
#Create new output file
$OutputCSVHeaderLine | Out-File $FullPathToOutputCSV

#Create CSV file object for input file
$InputCSVFile = Import-CSV -Path $FullPathToInputCSV -Delimiter $InputCSVDelimiter

#Iterate through CSV file
$LogMessage = "Looping through input file..."
Write-Log $LogMessage
foreach ($line in $InputCSVFile) {
    $WarrantyData = Retrieve-WarrantyData -AuthToken $AuthenticationResult -DellSvcTag $($line.$InputCSVComputerSerialNumberColumnTitle)
    $ShipDate = $($WarrantyData.ShipDate)

    #Because one device can have various warranties, just grab the biggest (maximum) date
    $EntitlementEndDate = ($($WarrantyData.entitlements.endDate) | measure -maximum).maximum

    #$WarrantyData

    #Build new line for output CSV file
    $CSVLine = "$($line.$InputCSVComputerNameColumnTitle),$($ShipDate),$($EntitlementEndDate)"

    #Append new line to output CSV file
    $CSVLine | Out-File $FullPathToOutputCSV -Append

    #Log what we're doing
    $LogMessage = "Writing warranty data for computer $($line.$InputCSVComputerNameColumnTitle) $($line.$InputCSVComputerSerialNumberColumnTitle) to output CSV file..."
    Write-Log $LogMessage
}

#TODO: Write code to detect if the custom fields exist already and create them if they don't. Currently it just blindly tries to create them on every run.

#Create custom fields
& $PDQInvExecPath CreateCustomField -Name "$ShipDateCustomFieldName" -Type DateTime
& $PDQInvExecPath CreateCustomField -Name "$EntitlementEndDateCustomFieldName" -Type DateTime

#Import data into PDQ Inventory
$LogMessage = "Importing data into PDQ Inventory..."
Write-Log $LogMessage
#https://www.pdq.com/blog/adding-custom-fields-multiple-computers-powershell/
& $PDQInvExecPath ImportCustomFields -FileName "$FullPathToOutputCSV" -ComputerColumn "Computer Name" -CustomFields "$ShipDateCustomFieldName=$ShipDateCustomFieldName,$EntitlementEndDateCustomFieldName=$EntitlementEndDateCustomFieldName" -AllowOverwrite
#TODO: Wrap this into a function

$LogMessage = "Closing log file."
Write-Log $LogMessage

#-------------------------- End main script body --------------------------
